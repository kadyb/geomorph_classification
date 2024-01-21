import os
import numpy
import pandas
import skimage.io
import tensorflow as tf
import matplotlib.pyplot as plt
os.environ["KMP_DUPLICATE_LIB_OK"] = "True"
exec(open("unet_model.py").read()) # load U-Net model


### functions ---------------------------------------------------------

def list_files(catalog, wd = os.getcwd()):
    path = os.path.join(wd, catalog)
    files = os.listdir(path)
    files = [i for i in files if i.endswith((".tif"))]
    files = [os.path.join(wd, path, i) for i in files]
    return files

def load_images(paths):
    lst = []
    for i in range(len(paths)):
        img = skimage.io.imread(paths[i])
        if img.shape != (128, 128):
            # order == 0 is nearest-neighbor resampling
            img = skimage.transform.resize(img, (128, 128), order = 0)
        lst.append(img)
    return lst
    
def preprocess_arrays(img_array, mask_array):
    
    img = tf.convert_to_tensor(img_array)
    img = tf.expand_dims(img, axis = 2)
    
    mask = tf.convert_to_tensor(mask_array)
    mask = tf.expand_dims(mask_array, axis = 2)
    
    return img, mask

def dataset_augmentation(dataset):
    # x == img_array; y == mask_array
    augmentation = dataset.map(lambda x, y:(tf.image.flip_left_right(x), tf.image.flip_left_right(y)))
    dataset_augmented = tf.data.Dataset.concatenate(dataset, augmentation)
    augmentation = dataset.map(lambda x, y:(tf.image.flip_up_down(x), tf.image.flip_up_down(y)))
    dataset_augmented = tf.data.Dataset.concatenate(dataset_augmented, augmentation)
    augmentation = dataset.map(lambda x, y:(tf.image.flip_left_right(x), tf.image.flip_left_right(y)))
    augmentation = augmentation.map(lambda x, y:(tf.image.flip_up_down(x), tf.image.flip_up_down(y)))
    dataset_augmented = tf.data.Dataset.concatenate(dataset_augmented, augmentation)
    return dataset_augmented

def plot_results(idx):
    true_img = smpl_imgs[idx]
    true_img = true_img[None, ..., None]
    pred_img = unet_model.predict(true_img)
    pred_img = tf.argmax(pred_img, axis = -1)
    pred_img = pred_img[0, :, :]
    
    fig, (ax1, ax2) = plt.subplots(1, 2)
    ax1.matshow(pred_img)
    ax1.set_title('PREDICTED')
    ax1.axis('off')
    ax2.matshow(smpl_masks[idx])
    ax2.set_title('TRUE')
    ax2.axis('off')

### code --------------------------------------------------------------

## load all images into memory
img_paths = list_files("variable")
smpl_imgs = load_images(img_paths)

mask_paths = list_files("reference")
smpl_masks = load_images(mask_paths)

## check category distribution
distr = numpy.concatenate(smpl_masks).ravel()
distr = pandas.DataFrame(distr)
tab1 = pandas.DataFrame(distr).value_counts(normalize = True) * 100 # ID == 0 means NA

## create TF dataset
BATCHSIZE = 8
smpl_dataset = tf.data.Dataset.from_tensor_slices((smpl_imgs, smpl_masks))
smpl_dataset = smpl_dataset.map(preprocess_arrays)
smpl_dataset = smpl_dataset.shuffle(BATCHSIZE * 128, reshuffle_each_iteration = False)

## create training dataset
size = numpy.floor(len(smpl_imgs) * 0.8)
training_dataset = smpl_dataset.take(size)
training_dataset = dataset_augmentation(training_dataset) ## augmentation
training_dataset = training_dataset.shuffle(BATCHSIZE * 128, reshuffle_each_iteration = True)
training_dataset = training_dataset.batch(BATCHSIZE)

## create validation dataset
validation_dataset = smpl_dataset.skip(size)
validation_dataset = validation_dataset.batch(BATCHSIZE)

## check training data distribution
## remember that the input dataset is augmented
distr = []
for images, labels in training_dataset.as_numpy_iterator():
  distr.append(labels)
distr = numpy.concatenate(distr).ravel()
numpy.unique(distr)
numpy.max(distr) # maximum category ID
tab2 = pandas.DataFrame(distr).value_counts(normalize = True) * 100 # ID == 0 means NA

## model training
unet_model = build_unet_model(max_class = 56)
unet_model.compile(optimizer = tf.keras.optimizers.Adam(),
                   loss = "sparse_categorical_crossentropy",
                   metrics = "accuracy")
history = unet_model.fit(training_dataset, validation_data = validation_dataset,
                         epochs = 5)

## plot
pandas.DataFrame(history.history).plot(figsize = (8, 5))
plt.show()

## plot sample result
idx = numpy.random.choice(len(smpl_dataset), 1)[0]
plot_results(idx)
