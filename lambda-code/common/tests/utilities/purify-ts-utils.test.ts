import { Left, Right } from "purify-ts/Either";
import { EitherAsync } from "purify-ts/EitherAsync";
import { describe, expect, it, vi } from "vitest";
import { EitherAsyncUtils } from "../../src/utilities/purify-ts-utils.ts";

describe("EitherAsyncUtils", () => {
  describe("right", () => {
    it("should return a Right containing the provided value", async () => {
      const result = await EitherAsyncUtils.right("success").run();

      expect(result).toEqual(Right("success"));
    });

    it("should return a Right containing undefined when no value is provided (void scenario)", async () => {
      const result = await EitherAsyncUtils.right().run();

      expect(result).toEqual(Right(undefined));
    });
  });

  describe("left", () => {
    it("should return a Left containing the provided value", async () => {
      const result = await EitherAsyncUtils.left("error").run();

      expect(result).toEqual(Left("error"));
    });
  });

  describe("rightOnLeft", () => {
    it("should preserve the Right value when the operation succeeds", async () => {
      const operation = EitherAsyncUtils.right("success");

      const result = await EitherAsyncUtils.rightOnLeft(operation).run();

      expect(result).toEqual(Right("success"));
    });

    it("should replace a Left with Right(undefined) when no fallback is provided (void scenario)", async () => {
      const operation = EitherAsyncUtils.left("error");

      const result = await EitherAsyncUtils.rightOnLeft(operation).run();

      expect(result).toEqual(Right(undefined));
    });

    it("should replace a Left with the provided fallback value", async () => {
      const operation = EitherAsyncUtils.left("error");

      const result = await EitherAsyncUtils.rightOnLeft(operation, {
        fallbackValue: "fallback",
      }).run();

      expect(result).toEqual(Right("fallback"));
    });

    it("should execute the side effect when the operation returns a Left", async () => {
      const sideEffect = vi.fn();
      const operation = EitherAsyncUtils.left("error");

      await EitherAsyncUtils.rightOnLeft(operation, { sideEffect }).run();

      expect(sideEffect).toHaveBeenCalledOnce();
      expect(sideEffect).toHaveBeenCalledWith("error");
    });

    it("should not execute the side effect when the operation returns a Right", async () => {
      const sideEffect = vi.fn();
      const operation = EitherAsyncUtils.right("success");

      await EitherAsyncUtils.rightOnLeft(operation, { sideEffect }).run();

      expect(sideEffect).not.toHaveBeenCalled();
    });
  });

  describe("ifRightAsync", () => {
    it("should execute the provided function with the Right value", async () => {
      const fn = vi.fn(() => EitherAsyncUtils.right("ignored"));
      const operation = EitherAsyncUtils.ifRightAsync(fn);

      const result = await operation("original").run();

      expect(fn).toHaveBeenCalledOnce();
      expect(fn).toHaveBeenCalledWith("original");
      expect(result).toEqual(Right("original"));
    });

    it("should preserve the original value regardless of the function's returned value", async () => {
      const operation = EitherAsyncUtils.ifRightAsync(() => EitherAsyncUtils.right("different"));

      const result = await operation("original").run();

      expect(result).toEqual(Right("original"));
    });

    it("should propagate a Left returned by the provided function", async () => {
      const operation = EitherAsyncUtils.ifRightAsync(() => EitherAsyncUtils.left("error"));

      const result = await operation("original").run();

      expect(result).toEqual(Left("error"));
    });

    it("should wait for the asynchronous function to complete", async () => {
      const fn = vi.fn(async () => {
        await Promise.resolve();
        return Right("ignored");
      });

      const result = await EitherAsyncUtils.ifRightAsync(() => EitherAsync(async () => fn()))("original").run();

      expect(fn).toHaveBeenCalledOnce();
      expect(result).toEqual(Right("original"));
    });

    it("should not convert a rejected operation into a Right", async () => {
      const operation = EitherAsyncUtils.ifRightAsync(() => EitherAsyncUtils.left("error"));

      const result = await operation("original").run();

      expect(result).toEqual(Left("error"));
    });
  });
});
