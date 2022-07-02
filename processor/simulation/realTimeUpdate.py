import cv2 as cv
import numpy as np

img = cv.imread('tower.jpg', cv.IMREAD_GRAYSCALE)

cv.imshow('image',img)
cv.waitKey(1000)

lineNo = 0

while(True):
    updates = open('updates.txt', 'r')
    imageByteUpdates = updates.readlines()
    while (lineNo < len(imageByteUpdates)):
        address, byte = imageByteUpdates[lineNo].split(' ')
        #print(address, byte)
        address = int(address) - 260
        row = address//400
        col = address%400
        img[row][col] = int(byte)
        lineNo += 1
    cv.imshow('image', img)
    cv.waitKey(1)

cv.destroyAllWindows()