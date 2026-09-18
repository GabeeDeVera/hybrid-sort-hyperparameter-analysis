import numpy as np

import tensorflow as tf
import pandas

# Preprocessing Data
data = pandas.read_csv("../data/performance_data.csv")
npdata = data.to_numpy()[..., 0:3].astype(np.float32)

inps = npdata[..., 0:2]
outs = npdata[..., 2:3]

# print(inps)
# print(outs)

# exit(0)

# Hyperparameters
EPOCHS = 1000

# Normalizing the output to stay within [0, 1]
def sigmoid_np(x):
    return ((x ** (1.0/3.0)) * (10.0 ** 1.5)) / (1 + (np.abs(x) ** (1.0/3.0)) * (10.0 ** 1.5))

def sigmoid_tf(x):
    return ((x ** (1.0/3.0)) * (10.0 ** 1.5)) / (1 + (tf.abs(x) ** (1.0/3.0)) * (10.0 ** 1.5))

# Functions to Calculate R^2
def avg(a):
    return sum(a) / len(a)

def ss(a):
    return sum(map(lambda x: x**2, a))

def r_squared(data, pred):
    data_mean = avg(data)
    ss_tot = ss(list(map(lambda x: x - data_mean, data)))

    ss_resid = ss(list(map(lambda x: x[1] - x[0], zip(data, pred))))

    return 1.0 - ss_resid / ss_tot

"""
The runtime model is 
a n s + b n log n - b n log s

Where log is the natural log
"""
class RuntimeModel(tf.keras.Model):
    def __init__(self, do_output_norm, init_a = None, init_b = None, **kwargs):
        super().__init__(**kwargs)

        """
        We wish to initialize a and b so that the expectation of the norm of the parameter vector
        is equal to 1.

        This means that the standard deviation must be 1 / sqrt(2). See slides for the justification.
        """
        if((init_a is None) or (init_b is None)):
            std = 1.0 / (2.0 ** 0.5)
            init = tf.keras.initializers.RandomNormal(mean=0.0, stddev=std)
            self.a = self.add_weight(
                shape=(1, ), initializer=init, trainable=True
            )
            self.b = self.add_weight(
                shape=(1, ), initializer=init, trainable=True
            )
        else:
            self.a = self.add_weight(
                initializer=tf.keras.initializers.Constant(0.0036994091273325055), shape=(1, ), trainable=True
            )
            self.b = self.add_weight(
                initializer=tf.keras.initializers.Constant(0.011671713842091029), shape=(1, ), trainable=True
            )
        self.do_output_norm = do_output_norm 
        # self.a = tf.Variable(tf.random.normal(shape=(1, )), stddev=1.0/(2.0 ** 0.5), trainable=True)
        # self.b = tf.Variable(tf.random.normal(shape=(1, )), stddev=1.0/(2.0 ** 0.5), trainable=True)
    
    def eval_unnorm(self, inp):
        s, n = tf.split(inp, num_or_size_splits=2, axis=1)
        eps=1e-7
        pred_time = (self.a ** 2) * (n * s) + (self.b ** 2) * (n * tf.math.log(tf.maximum(n, eps))) - (self.b ** 2) * (n * tf.math.log(tf.maximum(s, eps)))
        return pred_time

    def call(self, inp):
        return sigmoid_tf(self.eval_unnorm(inp)) if self.do_output_norm else self.eval_unnorm(inp)

"""
RUNNING MODEL 1: NORMED OUTPUT (For Stability)
"""
normed_runtime_model = RuntimeModel(True)

# Compile sets the training parameters
normed_runtime_model.compile(
    run_eagerly=False,
    optimizer=tf.keras.optimizers.Adam(
        # learning_rate=tf.keras.optimizers.schedules.ExponentialDecay(
        #     initial_learning_rate=0.01,
        #     decay_steps=inps.shape[1]*EPOCHS,
        #     decay_rate=1e-3
        # ),
        learning_rate=5e-3,
        clipnorm=1,
    ),
    loss=tf.keras.losses.MeanSquaredError(),
)

# Fit the model to the data
normed_runtime_model.fit(inps, sigmoid_np(outs), epochs=EPOCHS, batch_size=inps.shape[0],
    verbose=1
    # callbacks=[tf.keras.callbacks.TerminateOnNaN()]
)

# Computing Approximate a and b
approx_a = list(normed_runtime_model.a.numpy())[0] ** 2
approx_b = list(normed_runtime_model.b.numpy())[0] ** 2
print("PRELIMINARY RESULTS")
print(f"a = {approx_a}")
print(f"b = {approx_b}")
print(f"s ~ {approx_b / approx_a}")

"""
RUNNING MODEL 2: UNNORMALIZED (For Precise Tuning)
"""
runtime_model = RuntimeModel(False, approx_a, approx_b)

# Compile sets the training parameters
runtime_model.compile(
    run_eagerly=False,
    optimizer=tf.keras.optimizers.Adam(
        # learning_rate=tf.keras.optimizers.schedules.ExponentialDecay(
        #     initial_learning_rate=0.01,
        #     decay_steps=inps.shape[1]*EPOCHS,
        #     decay_rate=1e-3
        # ),
        learning_rate=5e-6,
        clipnorm=1,
    ),
    loss=tf.keras.losses.MeanSquaredError(),
)

# Fit the model to the data
runtime_model.fit(inps, outs, epochs=EPOCHS, batch_size=inps.shape[0],
    verbose=1
    # callbacks=[tf.keras.callbacks.TerminateOnNaN()]
)

# Computing a and b
approx_a = list(runtime_model.a.numpy())[0] ** 2
approx_b = list(runtime_model.b.numpy())[0] ** 2
print("FINAL RESULTS")
print(f"a = {approx_a}")
print(f"b = {approx_b}")
print(f"s ~ {approx_b / approx_a}")

# Computing R^2
y_pred = runtime_model.eval_unnorm(inps)

y_pred_list = list(map(lambda x: float(x[0]), y_pred.numpy()))

y_truth_list = list(map(lambda x: float(x[0]), outs))

print(f"R^2 = {r_squared(y_truth_list, y_pred_list)}")