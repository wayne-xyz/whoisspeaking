import pickle
import numpy as np
import uvicorn
from fastapi import FastAPI, Request
from pymongo import MongoClient
from basehandler import json_str
import turicreate as tc
from sklearn.neighbors import KNeighborsClassifier
from joblib import dump, load

def write_json(value={}):
    '''Completes header and writes JSONified 
        HTTP back to client
    '''
    return json_str(value)

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
    
supported_models = ["KNN", "SVM"]
client = MongoClient(serverSelectionTimeoutMS=50)
db = client.turidatabase
KNNclf, SVMclf = None, None
app = FastAPI()


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
    return write_json({"id":str(dbid),
        "feature":[str(len(fvals))+" Points Received",
                "min of: " +str(min(fvals)),
                "max of: " +str(max(fvals))],
        "label":label})


@app.get("/UpdateModel")
async def UpdateModel(dsid: int = 0, model_name: str = "KNN"):
    '''Train a new model (or update) for given dataset ID
    '''
    if model_name not in supported_models:
        return "model not supported!"


    # fit the model to the data
    acc = -1
    if model_name == "KNN":
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
            acc = sum(lstar==labels)/float(len(labels))

            # just write this to model files directory
            dump(model, '../models/sklearn_model_dsid%d.joblib'%(dsid))
    else:
        data = get_features_and_labels_as_SFrame(dsid)
        # fit the model to the data
        if len(data)>0:
            global SVMclf
            model = tc.classifier.svm_classifier.create(data,target='target',verbose=0)# training
            yhat = model.predict(data)
            SVMclf = model
            acc = sum(yhat==data['target'])/float(len(data))
            # save model for use later, if desired
            model.save('../models/turi_model_dsid%d'%(dsid))
            
    # send back the resubstitution accuracy
    # if training takes a while, we are blocking tornado!! No!!
    return write_json({"resubAccuracy":acc})
    

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
        if not KNNclf:
            # load from file if needed
            print('Loading Model From DB')
            tmp = load('../models/sklearn_model_dsid%d.joblib'%(dsid)) 
            KNNclf = pickle.loads(tmp['model'])
        
        model = KNNclf
    else:
        # load the model from the database (using pickle)
        # we are blocking tornado!! no!!
        if not SVMclf:
            print('Loading Model From file')
            SVMclf = tc.load_model('../models/turi_model_dsid%d'%(dsid))
        model = SVMclf
  
    predLabel = model.predict(fvals)
    return write_json({"prediction":str(predLabel)})


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)