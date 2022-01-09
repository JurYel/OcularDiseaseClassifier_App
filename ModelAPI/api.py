import os

from fastapi.datastructures import UploadFile
from numpy.lib.function_base import delete
from tensorflow.python.keras.backend import set_session
from tensorflow.keras.applications.imagenet_utils import decode_predictions
import cv2
from tensorflow import keras
import tensorflow.compat.v1 as tf
from tensorflow.keras.applications import mobilenet_v2
from tensorflow.keras.applications.imagenet_utils import decode_predictions
from tensorflow.compat.v1 import Graph, Session

import uvicorn
import pathlib

import numpy as np
 
from fastapi import FastAPI, UploadFile, File

from PIL import Image
from io import BytesIO

import shutil


BASE_DIR = pathlib.Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "./model/odir/"

print(MODEL_PATH)


model_graph = Graph()
with model_graph.as_default():
    tf_session = Session()
    with tf_session.as_default():
        
        print('-------------Loading Model...')
        model = keras.models.load_model(MODEL_PATH)
        print('-------------Model Loaded!')
        

app = FastAPI()

labels = ['normal', 'cataract', 'glaucoma', 'myopia']

@app.get('/')
def index():
    return {'message': 'Ocular Disease Detection'}

@app.post('/predict')
async def predict(file: UploadFile = File(...)):

    with open(f'{file.filename}', "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)


    print('CONTENT TYPE: ')
    print(file.content_type)
    print('FILE NAME')
    print(file.filename)

    orig_img = keras.preprocessing.image.load_img(os.path.join(BASE_DIR, file.filename), target_size=(256, 256), color_mode='rgb')
    numpy_img = keras.preprocessing.image.img_to_array(orig_img)

    
    image_batch = np.expand_dims(numpy_img, axis=0)
    print(image_batch.shape)

    with model_graph.as_default():
            with tf_session.as_default():
                predictions = model.predict(image_batch)


    label_index = np.argmax(predictions)

    label = labels[label_index]
    confidence = predictions[0][label_index] * 100


    print('PREDICTIONS: ')
    print(predictions)
    print('LABEL: ')
    print(labels[label_index])
    print('CONFIDENCE: ')
    print(predictions[0][label_index] * 100)

    os.remove(file.filename)

    return {"label": label, "confidence": confidence}

if __name__ == '__main__':
    uvicorn.run(app, host='127.0.0.1', port=8000)