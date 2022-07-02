import cv2 as cv
import numpy as np

img = cv.imread('tower.jpg', cv.IMREAD_GRAYSCALE)

height, width = img.shape

imageFile = open('imageFile.txt', 'w')

#imageFile.writelines('\n'.join([str(height%256), str(height//256), str(width%256), str(width//256)]))

byteArray = [str(height%256), str(height//256), str(width%256), str(width//256)]

for rowIndex in range(height):
    print(rowIndex)
    for colIndex in range(width):
        byteArray.append(str(img[rowIndex][colIndex]))

imageFile.writelines('\n'.join(byteArray))

imageFile.close()