import os

from fastapi.datastructures import UploadFile
from numpy.lib.function_base import delete
from tensorflow.python.keras.backend import set_session
from tensorflow.keras.applications.imagenet_utils import decode_predictions
import cv2
import matplotlib as plt
from tensorflow import keras
import imutils
import tensorflow.compat.v1 as tf
from tensorflow.keras.applications import mobilenet_v2
from tensorflow.keras.applications.imagenet_utils import decode_predictions
from tensorflow.compat.v1 import Graph, Session
import glob

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


    
    # image_batch = np.expand_dims(numpy_img, axis=0)
    # print(image_batch.shape)

    uploaded_image = cv2.imread(os.path.join(BASE_DIR, file.filename))
    cv2.imwrite(os.path.join(BASE_DIR, file.filename)[:-3] + 'jpg', uploaded_image)
    file_name = os.path.join(BASE_DIR, file.filename)[:-3] + 'jpg'
    print(file_name)
    file_img = cv2.imread(file_name)
    file_img = cv2.cvtColor(file_img, cv2.COLOR_BGR2RGB)
    print(file_img.shape)
    #print(expanded.shape)

    cropped_image = crop_image(file_img)
    # cropped_image = crop_contour_retinal_image(file_img)
    numpy_img = keras.preprocessing.image.img_to_array(cropped_image)
    cv2.imwrite("something.jpg", cropped_image)
    expanded = np.expand_dims(numpy_img, axis=0)


    with model_graph.as_default():
            with tf_session.as_default():
                predictions = model.predict(expanded)


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


def crop_image(image, plot=False, image_size=(256, 256)):
  # mask of colored pixels
  mask = image > 10

  print('START')
  # coordinates of colored pixels
  coordinates = np.argwhere(mask)

  # binding box of non-black pixels
  x0, y0, s0 = coordinates.min(axis=0)
  x1, y1, s1 = coordinates.max(axis=0) + 1 # slices are exclusive at the top

  # get the contents of the bounding box
  cropped = image[x0:x1, y0:y1]

  # convert to YUV for equalization
  img_yuv = cv2.cvtColor(cropped, cv2.COLOR_RGB2YUV)

  # apply adaptive equalization
  clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
  img_yuv[:, :, 0] = clahe.apply(img_yuv[:, :, 0])

  # apply image normalization
  mask = np.zeros((256, 256))
  normalized = cv2.normalize(img_yuv[:,:,0], mask, 0, 255, cv2.NORM_MINMAX)

  # convert back to rgb
  new_image = cv2.cvtColor(img_yuv, cv2.COLOR_YUV2RGB)

  new_image = cv2.resize(new_image, image_size, interpolation=cv2.INTER_AREA)

  final_image = cv2.cvtColor(new_image, cv2.COLOR_RGB2BGR)

  if plot:
    plt.subplot(1,2,1)
    plt.imshow(image)
    plt.title(f"Original - {image.shape}")
    plt.axis('off')
    plt.grid(False)

    # ----------------- #

    plt.subplot(1,2,2)
    plt.imshow(new_image)
    plt.title(f"Preprocessed - {new_image.shape}")
    plt.axis('off')
    plt.grid(False)
    plt.show()
  
  print('END')
  return final_image


def crop_contour_retinal_image(image, plot=False, image_size=(256, 256)):
  image = cv2.resize(image, None, fx=0.3, fy=0.3, interpolation=cv2.INTER_AREA)
  grayed = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
  grayed = cv2.GaussianBlur(grayed, (5,5), 0)
  thresh_image = cv2.erode(grayed, None, iterations=2)
  thresh_image = cv2.dilate(thresh_image, None, iterations=2)

  # find canny edges
  edges = cv2.Canny(thresh_image, 20, 70)

  # find contours
  contours = cv2.findContours(edges.copy, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
  contours = imutils.grab_contours(contours)
  c = max(contours, key=cv2.contourArea)

  # extract coords of largest contour
  extreme_pnts_left = tuple(c[c[:, :, 0].argmin()][0])
  extreme_pnts_right = tuple(c[c[:, :, 0].argmax()][0])
  extreme_pnts_top = tuple(c[c[:, :, 1].argmin()][0])
  extreme_pnts_bot = tuple(c[c[:, :, 1].argmax()][0])

  # crop image
  new_image = grayed[extreme_pnts_top[1]:extreme_pnts_bot[1], extreme_pnts_left[0]:extreme_pnts_right[0]]
  new_image = cv2.resize(new_image, image_size, interpolation=cv2.INTER_AREA)

  if plot:
    plt.subplot(1,2,1)
    plt.imshow(image)
    plt.title(f"Original - {image.shape}")
    plt.axis('off')
    plt.grid(False)

    # ----------------------------------- #
    
    plt.subplot(1,2,2)
    plt.imshow(new_image, cmap='gray', vmin=0, vmax=255)
    plt.title(f"Preprocesed - {new_image.shape}")
    plt.axis('off')
    plt.grid(False)

    plt.show()

  return new_image

if __name__ == '__main__':
    uvicorn.run(app, host='127.0.0.1', port=8000)