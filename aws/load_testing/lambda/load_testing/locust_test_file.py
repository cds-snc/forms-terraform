import logging
import random
import uuid
import json
from json import JSONDecodeError
from locust import HttpUser, task, between, events

logging.basicConfig(level=logging.INFO)

formIDs = ["28","29","30","31"]

formSubmissions ={
  "28":{
    "2": "Performance Testing",
    "3": "performance.testing@cds-snc.ca",
    "4": "Ontario",
    "formID": "28"
  },
  "29":{
    "2": "Performance Testing",
    "3": "performance.testing@cds-snc.ca",
    "4": "Alberta",
    "formID": "29"
  },
  "30":{
    "2": "Performance Testing",
    "3": "performance.testing@cds-snc.ca",
    "4": "New Brunswick",
    "formID":"30"
  },
  "31":{
    "2": "Performance Testing",
    "3": "performance.testing@cds-snc.ca",
    "4": "British Columbia",
    "formID": "31"
  }
}



class FormUser(HttpUser):
  wait_time = between(3,10)
  host = "https://forms-staging.cdssandbox.xyz"

  formDataSubmissions = {"success":[], "failed":[]}

  # Test 1: High hit count
  # Hit landing page
  # Choose one of the performance testing forms
  # Submit Form response based on form ID

  @classmethod
  def on_test_stop(self):
    output_file = open("/tmp/form_completion.json", "w")
    json.dump(self.formDataSubmissions, output_file)
    output_file.close()

  @task
  def formFill(self):
    lang = random.choice(["en", "fr"])
    # Get to welcome page
    self.client.get(f"/{lang}/welcome-bienvenue")
    
    # Go to a form page after 
    formID = random.choice(formIDs)
    self.client.get(f"/{lang}/id/{formID}")

    uniqueFormData = formSubmissions[formID]
    uniqueFormData["2"] = uuid.uuid4().hex

    # Submit the form
    with self.client.post("/api/submit", json=uniqueFormData, name=f"/api/submit?{formID}", catch_response=True) as response:
      try:
        
        if response.json()["received"] != True :
          self.formDataSubmissions["failed"].append(uniqueFormData["2"])
          response.failure(f"Submission failed for formID {formID}")
        else:
          self.formDataSubmissions["success"].append(uniqueFormData["2"])
      except JSONDecodeError:
        self.formDataSubmissions["failed"].append(uniqueFormData["2"])
        response.failure("Response could not be decoded as JSON")
      except KeyError:
        self.formDataSubmissions["failed"].append(uniqueFormData["2"])
        response.failure("Response did not have the expected receive key")

    # Go to confirmation page
    self.client.get(f"/{lang}/id/{formID}/confirmation")



  # Admin Users tests:
  #
  # Test 1: Low hit count
  # Login to Admin
  # Create form (upload)
  # Update form text (id/settings/)
  # Delete form (id/settings)
  #
  # Test 2: Med hit count
  # Login to Admin
  # Go to Form Templates list (view-templates)
  #
  # Test 3: Low hit count
  # Login to Admin
  # Go to Feature Flags
  #
  # Test 4: High hit count
  # Login to Admin
  # Retrieve responses for form
  # 
  # Test 5: Hight hit count
  # Login to Admin
  # Got to dashboard
