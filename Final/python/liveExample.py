#########################################################
# created time    : 2025/0506 21:00                     #
# last edited time: 2025/0508 21:00                     #
#########################################################

import cv2
import time
import numpy as np

if __name__ == '__main__':
  ### ---------------- parameters ---------------------
  mp4_fname = '../test.mp4'
  ofname = 'trajectories.output'
  frame_width = 105
  frame_height = 105
  overlap_w = 70
  overlap_h = 70

  line_width = 3
  traj_width = 5
  ### -------------------------------------------------
  # import the mp4 file
  cap = cv2.VideoCapture(mp4_fname)

  # check if camera opened successfully
  if not cap.isOpened():
    print('[Error] Can\'t open video file \"%s\"'% mp4_fname)
    exit(0)
  else:
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))      # the width of images
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))    # the height of images
    print("Video properties: ")
    print("Video Dimensions: %d x %d" % (width , height))
    print("Video FPS: %.4f" % cap.get(cv2.CAP_PROP_FPS))

    # initialize same parameters
    trajectory = np.int8(np.zeros((height, width, 3), int)) - 127 # an array consisting of 8-bit elements, initialized to a value of -127
    traj_list = list()                                            # the list to store the trajectories
    t = 0                                                         # the variable to record the number of images has been processed
    max_y, max_y_pre = 0, 0
    max_x, max_x_pre = 0, 0
    max_b = 0

  while( cap.isOpened() and t < 120):
    ret, img = cap.read()
    if ret:
        imgin = img[:, :, (0,1,2)]                                # notice that the order of color is BGR
    else:
      break

    ### Filter the color, default is blue
    is_blue = np.multiply(                                                         # notice the elements in "imgin" is 8-bits unsigned integral
                    (imgin[:,:,0] > np.maximum(imgin[:,:,1], imgin[:,:,1] + 40)),  # , it might overflow when processing them. 
                    (imgin[:,:,0] > np.maximum(imgin[:,:,2], imgin[:,:,2] + 40)))  # set entries HIHG if sub-pixcel B is bigger than G and R
    imgin[:,:,0] = is_blue*255
    imgin[:,:,1] = 0
    imgin[:,:,2] = 0

    ### Place frames and find the position
    # reset the position of the detecting frame at the top-left
    max_x = 0
    max_y = 0
    max_b = 0            # the total "is_blue==1" in the detecting frame

    ### Identify the areas within an image that contain the highest concentration of "is_blue" attributes.     
    for x in range(0, width, frame_width - overlap_w):
      for y in range(0, height, frame_height - overlap_h):
        if np.sum(is_blue[y: y + frame_height - 1, x: x + frame_width - 1]) > max_b: # find the place with higher concentration
          max_x = x
          max_y = y
          max_b = np.sum(is_blue[y: y + frame_height - 1, x: x + frame_width - 1])
    
    
    ### Draw the final place of the detecting frame
    # only the top-left is real
    img[max_y                   : max_y + line_width,                    max_x                  : max_x + frame_width - 1,              2] = 200
    img[max_y                   : max_y + line_width,                    max_x                  : max_x + frame_width - 1,              0] = 0
    img[max_y + frame_height - 1: max_y + frame_height - 1 + line_width, max_x                  : max_x + frame_width - 1,              2] = 200
    img[max_y + frame_height - 1: max_y + frame_height - 1 + line_width, max_x                  : max_x + frame_width - 1,              0] = 0
    img[max_y                   : max_y + frame_height - 1             , max_x                  : max_x + line_width,                   2] = 200
    img[max_y                   : max_y + frame_height - 1             , max_x                  : max_x + line_width,                   0] = 0
    img[max_y                   : max_y + frame_height - 1             , max_x + frame_width - 1: max_x + frame_width - 1 + line_width, 2] = 200
    img[max_y                   : max_y + frame_height - 1             , max_x + frame_width - 1: max_x + frame_width - 1 + line_width, 0] = 0
    
    ### Store the position of the detecting frame
    if (t) : 
      traj_list.append((max_x_pre, max_y_pre, max_x, max_y))
    
    ### Draw the trajectory
      traj_line_x = np.linspace(max_x_pre, max_x, frame_width - overlap_w)
      traj_line_y = np.linspace(max_y_pre, max_y, frame_height - overlap_h)
      for n in range(1, frame_height-overlap_h):
        trajectory[int(traj_line_y[n]) - 1 : int(traj_line_y[n]) + 1,
                   int(traj_line_x[n]) - 1 : int(traj_line_x[n]) + 1
                  ] = [0 , (7 + t*2)%128, -127]
    ### 
    t = t + 1
    max_x_pre = max_x
    max_y_pre = max_y

    ### Ensure that the video is configured to play in real-time
    time.sleep(1/60)
    cv2.imshow("camOut", img)
    cv2.waitKey(1)
  
  ### Show the result on the screen
  cv2.imshow("camOut", trajectory)
  cv2.waitKey(0)
  # cv2.imshow("camOut", np.int8(np.zeros((height, width, 3), int))-127)
  # cv2.waitKey(0)
  cap.release()
  
  ### Export the data
  # the first line is the dimensions of the image
  # the rest of lines have four element
  # 
  with open(ofname, 'w') as of:
    of.write("%d %d\n" % (width, height))
    for a,b,c,d in traj_list:
      of.write("%d %d %d %d\n" % (a,b,c,d))