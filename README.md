# Ocular Disease Detection from Fundoscopic Imagery
 An ocular disease detection of fundoscopic images capable of detecting four classes (Normal, Cataract, Glaucoma, High Myopia) with high accuracy.
 This project utilizes **[Tensorflow](https://www.tensorflow.org/resources/learn-ml?gclid=Cj0KCQiA64GRBhCZARIsAHOLriIqnzLGQrh_xzVj4Cvr_VRB18TMXRIzqynmX__UxXfvbvyguQC2oY8aAuEPEALw_wcB)** and **[Keras](https://keras.io/)** in the construction of the model, **[Flutter](https://flutter.dev/)** and **[FastAPI](https://fastapi.tiangolo.com/)** web framework are used in the development of the android application and integration of the model in the application.

### Developed Deep Learning Model
![ResNet128-BNCReLU](https://github.com/JurYel/OcularDiseaseClassifier_App/blob/master/assets/model.PNG)

The developed deep learning model consists of 128 layers divided into 12 residual blocks, each with Concatenated Rectified Linear Units (CReLU) underneath, replacing vanilla ReLUs to resolve its drawbacks of non-differentiability at zero values and its unbounded nature. 

The data is first enhanced using Contrast Limited Adaptive Equalization (CLAHE), giving more emphasis on the features of the fundus image then it is fed to the model and is trained using a weighted loss function to account for the skewed data distribution, then softmax as its final activation function for the distributed prediction probabilities on each class, and lastly output a classification. To visualize the features focused by the model upon classification, Gradient-Weighted Class Activation Mapping (Grad-CAM) is used to show which features or factors are prioritized on model inference.

----------------------
Authors:
* [Juriel Botoy](https://github.com/JurYel)
* [Kyle Kettenacker](https://github.com/klkettenacker)
* [Ian Jee Garbo](https://github.com/ejeegarbo)
 
