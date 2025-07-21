import re
import time
from locust import User
from locust.exception import LocustError
import httpx
from httpx import Request, Response
from requests.auth import HTTPBasicAuth
from httpx import InvalidURL, RequestError
from urllib.parse import urlparse, urlunparse
from locust.exception import CatchResponseError, ResponseError

absolute_http_url_regexp = re.compile(r"^https?://", re.I)


class LocustResponse(Response):
    def raise_for_status(self):
        if hasattr(self, "error") and self.error:
            raise self.error
        Response.raise_for_status(self)


class HttpSession(httpx.Client):
    def __init__(self, base_url, request_trigger, *args, **k):
        super().__init__(*args, **k)

        self.base_url = base_url
        self.request_trigger = request_trigger

        # Check for basic authentication
        parsed_url = urlparse(str(self.base_url))
        if parsed_url.username and parsed_url.password:
            netloc = parsed_url.hostname
            if parsed_url.port:
                netloc += ":%d" % parsed_url.port

            # remove username and password from the base_url
            self.base_url = urlunparse(
                (
                    parsed_url.scheme,
                    netloc,
                    parsed_url.path,
                    parsed_url.params,
                    parsed_url.query,
                    parsed_url.fragment,
                )
            )
            # configure requests to use basic auth
            self.auth = HTTPBasicAuth(parsed_url.username, parsed_url.password)

    def _build_url(self, path):
        """prepend url with hostname unless it's already an absolute URL"""
        if absolute_http_url_regexp.match(path):
            return path
        else:
            return "%s%s" % (self.base_url, path)

    def request(self, method, url, name=None, catch_response=False, **kwargs):
        # prepend url with hostname unless it's already an absolute URL
        url = self._build_url(url)

        # store meta data that is used when reporting the request to locust's
        # statistics
        request_meta = {}

        # set up pre_request hook for attaching meta data to the request object
        request_meta["method"] = method
        request_meta["start_time"] = time.monotonic()

        response = self._send_request_safe_mode(method, url, **kwargs)

        # record the consumed time
        request_meta["response_time"] = (
            time.monotonic() - request_meta["start_time"]
        ) * 1000

        request_meta["name"] = str(name or response.request.url)

        # get the length of the content, but if the argument stream is set to
        # True, we take the size from the content-length header, in order to
        # not trigger fetching of the body
        if kwargs.get("stream", False):
            request_meta["content_size"] = int(
                response.headers.get("content-length") or 0
            )
        else:
            request_meta["content_size"] = len(response.content or b"")

        if catch_response:
            response.locust_request_meta = request_meta
            return ResponseContextManager(
                response,
                request_trigger=self.request_trigger,
            )
        else:
            if name:
                # Since we use the Exception message when grouping failures, in
                # order to not get multiple failure entries for different URLs
                # for the same name argument, we need to temporarily override
                # the response.url attribute
                orig_url = response.url
                response.url = name
            try:
                response.raise_for_status()
            except httpx.HTTPError as e:
                self.request_trigger.fire(
                    request_type=request_meta["method"],
                    name=request_meta["name"],
                    response_time=request_meta["response_time"],
                    response_length=request_meta["content_size"],
                    exception=e,
                )
            else:
                self.request_trigger.fire(
                    request_type=request_meta["method"],
                    name=request_meta["name"],
                    response_time=request_meta["response_time"],
                    response_length=request_meta["content_size"],
                )
            if name:
                response.url = orig_url
            return response

    def _send_request_safe_mode(self, method, url, **kwargs):
        """
        Send an HTTP request, and catch any exception that might occur due to
        connection problems.

        Safe mode has been removed from requests 1.x.
        """
        try:
            return super().request(method, url, **kwargs)
        except (InvalidURL,):
            raise
        except RequestError as e:
            r = LocustResponse(status_code=0)
            r.error = e
            r.request = Request(method, url)
            return r


class ResponseContextManager(LocustResponse):
    """
    A Response class that also acts as a context manager that provides the
    ability to manually control if an HTTP request should be marked as
    successful or a failure in Locust's statistics

    This class is a subclass of :py:class:`Response <requests.Response>` with
    two additional

    methods: :py:meth:`success <locust.clients.ResponseContextManager.success>`
    and :py:meth:`failure <locust.clients.ResponseContextManager.failure>`.
    """

    _manual_result = None
    locust_request_meta: dict

    def __init__(self, response, request_trigger):
        # copy data from response to this object
        self.__dict__ = response.__dict__
        self.request_trigger = request_trigger

    def __enter__(self):
        return self

    def __exit__(self, exc, value, traceback):
        if self._manual_result is not None:
            if self._manual_result is True:
                self._report_success()
            elif isinstance(self._manual_result, Exception):
                self._report_failure(self._manual_result)

            # if the user has already manually marked this response as failure
            # or success we can ignore the default behaviour of letting the
            # response code determine the outcome
            return exc is None

        if exc:
            if isinstance(value, ResponseError):
                self._report_failure(value)
            else:
                # we want other unknown exceptions to be raised
                return False
        else:
            try:
                self.raise_for_status()
            except httpx.HTTPError as e:
                self._report_failure(e)
            else:
                self._report_success()

        return True

    def _report_success(self):
        self.request_trigger.fire(
            request_type=self.locust_request_meta["method"],
            name=self.locust_request_meta["name"],
            response_time=self.locust_request_meta["response_time"],
            response_length=self.locust_request_meta["content_size"],
        )

    def _report_failure(self, exc):
        self.request_trigger.fire(
            request_type=self.locust_request_meta["method"],
            name=self.locust_request_meta["name"],
            response_time=self.locust_request_meta["response_time"],
            response_length=self.locust_request_meta["content_size"],
            exception=exc,
        )

    def success(self):
        self._manual_result = True

    def failure(self, exc):
        if not isinstance(exc, Exception):
            exc = CatchResponseError(exc)
        self._manual_result = exc


class Http2User(User):

    abstract = True
    http2 = True

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.host is None:
            raise LocustError(
                "You must specify the base host. Either in the host attribute "
                "in the User class, or on the command line using the --host "
                "option."
            )
        self.client = HttpSession(
            base_url=self.host,
            http2=self.http2,
            request_trigger=self.environment.events.request,
        )
