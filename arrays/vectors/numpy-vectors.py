import pickle
import string
import random
import os.path
import numpy as np
from numpy import random

# take user input to take the amount of data
number_of_data = 1000

# define the checkpointing rate:
crate=10

# some time-intesive calculation:
def vector_dot():
        # define array size:
        array_size = 2000000
        a = random.randint(100, size=(array_size))
        b = random.randint(100, size=(array_size))
        c = np.zeros(array_size, dtype=int)
        for i in range(array_size):
                c[i] = a[i] * b[i]
        return np.sum(c)

def main():

        # check if a checkpoint file exists:
        if os.path.isfile('checkpoint.pickle'):
                with open("checkpoint.pickle", "rb") as f:
                        step,data = pickle.load(f)
                f.close()
        else:
                #no previous checkpoints exist, start from the beginning:
                step=1
                data = []

        print('Starting calculation from iteration: ' + str(step))

        if step<number_of_data:
                #continue iterations:
                for i in range(step, number_of_data):
                        print('Calculating step: ' + str(i))
                        # Perform "heavy" calculation:
                        s = vector_dot()
                        data.append(s)
                        #create a checkpoint each "crate" steps:
                        if (i % crate == 0):
                                #open/overwrite the previous checkpoint:
                                with open("checkpoint.pickle", "wb") as f:
                                        pickle.dump((i,data), f)
                                f.close()
                                print('Finished checkpointing step: ' + str(i))
        else:
                print('The total number of steps: ' + str(number_of_data) + ' has been reached. Program complete.')


if __name__ == "__main__":
        main()
