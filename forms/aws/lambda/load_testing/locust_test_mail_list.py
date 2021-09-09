import logging
import random
import uuid
import json
from json import JSONDecodeError
from locust import HttpUser, task, between, events

logging.basicConfig(level=logging.INFO)

formSubmissions = {

  "en":[
    {
    "2":'{"value":["Immigration program for Afghans who assisted the Government of Canada and their eligible family members."]}',
    "4":'{"value":["English"]}',

    },
    {
    "2":'{"value":["Humanitarian program to help Afghan nationals resettle to Canada."]}',
    "4":'{"value":["English"]}',

    },
    {
    "2":'{"value":["Immigration program for Afghans who assisted the Government of Canada and their eligible family members."]}',
    "4":'{"value":["French"]}',
    },
    {
    "2":'{"value":["Humanitarian program to help Afghan nationals resettle to Canada."]}',
    "4":'{"value":["French"]}'
    },
    {
    "2":'{"value":["Immigration program for Afghans who assisted the Government of Canada and their eligible family members.","Humanitarian program to help Afghan nationals resettle to Canada."]}',
    "4":'{"value":["English","French"]}'
    }
  ],
  "fr":[
    {
    "2":'{"value":["Programme d’immigration pour les Afghans qui ont aidé le gouvernement du Canada et les membres admissibles de leurs familles."]}',
    "4":'{"value":["Anglais"]}',
    },
    {
    "2":'{"value":["Programme humanitaire pour aider les afghans à s’installer au Canada."]}',
    "4":'{"value":["Anglais"]}',
    },
    {
    "2":'{"value":["Programme d’immigration pour les Afghans qui ont aidé le gouvernement du Canada et les membres admissibles de leurs familles."]}',
    "4":'{"value":["Français"]}',
    },
    {
    "2":'{"value":["Programme humanitaire pour aider les afghans à s’installer au Canada."]}',
    "4":'{"value":["Français"]}'
    },
    {
    "2":'{"value":["Programme d’immigration pour les Afghans qui ont aidé le gouvernement du Canada et les membres admissibles de leurs familles.","Programme humanitaire pour aider les afghans à s’installer au Canada."]}',
    "4":'{"value":["Anglais","Français"]}'
    }
  ]
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
    formID = "81"
    self.client.get(f"/{lang}/id/{formID}")

    uniqueFormDataArray = formSubmissions[lang]
    uniqueFormData = random.choice(uniqueFormDataArray)
    uniqueFormData["3"] = "success@simulator.amazonses.com"
    uniqueFormData["formID"] = formID

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

