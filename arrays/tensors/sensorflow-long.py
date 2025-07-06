import os
import sys
import os.path
import tensorflow as tf
from tensorflow import keras

print(tf.version.VERSION)

#####Get an example dataset - we'll use the MNIST dataset first 1000 examples:
(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

train_labels = train_labels[:5000]
test_labels = test_labels[:5000]

train_images = train_images[:5000].reshape(-1, 28 * 28) / 255.0
test_images = test_images[:5000].reshape(-1, 28 * 28) / 255.0

##epoch number of steps for each job, get it as a commandline argument:
epoch_steps=int(sys.argv[1])

####Define a simple sequential model:
def create_model():
  model = tf.keras.models.Sequential([
    keras.layers.Dense(512, activation='relu', input_shape=(784,)),
    keras.layers.Dropout(0.2),
    keras.layers.Dense(10)
  ])

  model.compile(optimizer='adam',
                loss=tf.losses.SparseCategoricalCrossentropy(from_logits=True),
                metrics=[tf.metrics.SparseCategoricalAccuracy()])

  return model


# Include the epoch in the file name (uses `str.format`)
checkpoint_path = "{epoch:d}.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)

# Create a callback that saves the model's weights every 5 epochs
cp_callback = tf.keras.callbacks.ModelCheckpoint(
    filepath=checkpoint_path,
    verbose=1,
    save_weights_only=True,
    period=5)

# Create a new model instance
model = create_model()

if os.path.exists(checkpoint_dir):

        latest = tf.train.latest_checkpoint(checkpoint_dir)

        # Load the previously saved weights, if there are any:
        model.load_weights(latest)

        # Re-evaluate the model
        loss, acc = model.evaluate(test_images,  test_labels, verbose=2)
        print("Restored model, accuracy: {:5.2f}%".format(100*acc))

        #Get step number:
        ckpt = tf.train.get_checkpoint_state(checkpoint_dir)
        step = int(os.path.basename(ckpt.model_checkpoint_path).split('.')[0])
        print('Continuing calculation from epoch step:' + str(step))
        initialEpoch=step
else:
        initialEpoch=0
        # Save the weights using the `checkpoint_path` format
        model.save_weights(checkpoint_path.format(epoch=0))

# Train the model with the new callback
model.fit(train_images,
          train_labels,
          epochs=epoch_steps,
          initial_epoch=initialEpoch,
          callbacks=[cp_callback],
          validation_data=(test_images,test_labels),
          verbose=1)
