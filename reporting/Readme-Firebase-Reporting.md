# Firebase - Rendering Reports from Realtime Database

To create reports from data stored in Firebase using [Firebase Python SDK](https://firebase.google.com/docs/admin/setup#python)

1. Get Firebase Credential File - in firebase console goto Project Settings > Service account
2. Select Python and generate credential json file and put your reporting folder
3. Install the firebase_admin SDK via pip or the like
4. Add the following code to the render_reports.py script to use the DB rather than json files




https://firebase.google.com/docs/reference/admin/python


```
import firebase_admin
from firebase_admin import credentials
```

In the run all section add the collowing code


```
    #
    cred = credentials.Certificate("SAMPLE_CREDENITAL.json")
    #firebase_admin.initialize_app(cred)
    databaseURL = "https://SAMPLE_URL.firebaseio.com/"
    default_app = firebase_admin.initialize_app(cred, {'databaseURL':databaseURL })

    from firebase_admin import db
    ref = db.reference("/surveys")


    # Retrieve surveys from db
    surveys = ref.get()
```
