import pickle
import numpy as np
import uvicorn
from fastapi import FastAPI, Request
from pymongo import MongoClient
from basehandler import json_str
import turicreate as tc
from sklearn.neighbors import KNeighborsClassifier
from joblib import dump, load
import os

app = FastAPI()

def get_features_and_labels_as_SFrame(dsid):
    # create feature vectors from database
    features=[]
    labels=[]
    for a in db.labeledinstances.find({"dsid":dsid}): 
        features.append([float(val) for val in a['feature']])
        labels.append(a['label'])

    # convert to dictionary for tc
    data = {'target':labels, 'sequence':np.array(features)}

    # send back the SFrame of the data
    return tc.SFrame(data=data)

def get_features_as_SFrame(vals):
    # create feature vectors from array input
    # convert to dictionary of arrays for tc

    tmp = [float(val) for val in vals]
    tmp = np.array(tmp)
    tmp = tmp.reshape((1,-1))
    data = {'sequence':tmp}

    # send back the SFrame of the data
    return tc.SFrame(data=data)
    

@app.post("/AddDataPoint")
async def AddDataPoint(request: Request):
    '''Save data point and class label to database
    '''
    data = await request.json()

    vals = data['feature']
    fvals = [float(val) for val in vals]
    label = data['label']
    sess  = data['dsid']

    dbid = db.labeledinstances.insert_one(
        {"feature":fvals,"label":label,"dsid":sess}
        )
    return json_str({"id":str(dbid),
        "feature":[str(len(fvals))+" Points Received",
                "min of: " +str(min(fvals)),
                "max of: " +str(max(fvals))],
        "label":label})


@app.get("/UpdateModel")
async def UpdateModel(dsid: int = 0):
    '''Train two new models (or update) for given dataset ID
    '''
    # fit the model to the data
    ###### KNN
    KNNacc = -1
    # create feature vectors and labels from database
    features = []
    labels   = []
    for a in db.labeledinstances.find({"dsid":dsid}): 
        features.append([float(val) for val in a['feature']])
        labels.append(a['label'])
    
    model = KNeighborsClassifier(n_neighbors=1)
    if labels:
        global KNNclf
        model.fit(features,labels) # training
        lstar = model.predict(features)
        KNNclf = model
        KNNacc = sum(lstar==labels)/float(len(labels))

        # just write this to model files directory
        os.makedirs("models", exist_ok=True)
        dump(model, 'models/knn_model_dsid%d.joblib'%(dsid))
        
    ####### BT 
    BTacc = -1
    data = get_features_and_labels_as_SFrame(dsid)
    # fit the model to the data
    if len(data)>0:
        global BTclf
        model = tc.classifier.boosted_trees_classifier.create(data,target='target',verbose=0)# training
        yhat = model.predict(data)
        BTclf = model
        BTacc = sum(yhat==data['target'])/float(len(data))
        # save model for use later, if desired
        os.makedirs("models", exist_ok=True)
        model.save('models/turi_model_dsid%d'%(dsid))
            
    # send back the resubstitution accuracy
    # if training takes a while, we are blocking tornado!! No!!
    return json_str({"KNNAccuracy": KNNacc, "SVMAccuracy": BTacc})
    

@app.post("/PredictOne")
async def PredictOne(request: Request, model_name: str = "KNN"):
    '''Predict the class of a sent feature vector
    '''
    if model_name not in supported_models:
        return "model not supported!"
    
    data = await request.json()   
    
    vals = data['feature']
    fvals = [float(val) for val in vals]
    fvals = np.array(fvals).reshape(1, -1)
    dsid  = data['dsid']

    # load the model (using pickle)
    if model_name == "KNN":
        global KNNclf
        if not KNNclf:
            # load from file if needed
            print('Loading Model From DB')
            tmp = load('models/knn_model_dsid%d.joblib'%(dsid)) 
            KNNclf = tmp
        
        model = KNNclf
    else:
        # load the model from the database (using pickle)
        # we are blocking tornado!! no!!
        global BTclf
        if not BTclf:
            print('Loading Model From file')
            BTclf = tc.load_model('models/turi_model_dsid%d'%(dsid))
        model = BTclf
  
    predLabel = model.predict(fvals)
    return json_str({"prediction":str(predLabel)})


if __name__ == "__main__":
    supported_models = ["KNN", "BT"]
    client = MongoClient(serverSelectionTimeoutMS=50)
    db = client.turidatabase
    KNNclf, BTclf = None, None
    uvicorn.run(app, host="0.0.0.0", port=8080)