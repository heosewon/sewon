import os, sys, time

import glob
from PIL import Image

from datetime import datetime

def ImageSize(files) :
    size_x = []
    size_y = []
    
    for file in files :
        image = Image.open(file)
        size_x.append(image.size[0])
        size_y.append(image.size[1])
    
    x_min = min(size_x)
    y_min = min(size_y)
    total_x_size = x_min * len(files[0:6])
    total_y_size = y_min * len(files[0:4])

    return x_min, y_min, total_x_size, total_y_size

def ResizeToMin(files, x_min, y_min, total_x_size, total_y_size) :
    file_list = []
    
    for file in files :
        image = Image.open(file)
        resize_file = image.resize((x_min, y_min))
        file_list.append(resize_file)
    
    return file_list, total_x_size, total_y_size, x_min, y_min

def ImageMerge(file_list, total_x_size, total_y_size, x_min, y_min) :
    new_image = Image.new("RGB", (total_x_size, total_y_size), (256, 256, 256))

    x_loc = 0
    y_loc = 0
    
    for index in range(len(file_list)):
        area = (x_loc, y_loc)
        
        x_loc += x_min
        
        if x_loc == x_min * 6 :
            x_loc = 0
            y_loc += y_min
                
        new_image.paste(file_list[index], area)
        
    new_image.show()
    new_image.save(xf)
    print(filename + ' 파일이 생성 되었습니다.')
    time.sleep(3)
    sys.exit()
    
    
now = datetime.now()
nowdetail = now.strftime('%Y%m%d%H%M%S')

Image_path = input('※jpg 파일만 취급 \n\n 이미지 경로 :')

Image_path = Image_path + '\\'

filename = "Result-"+ format(nowdetail)

files = glob.glob(format(Image_path) + "*.jpg")

xf = Image_path + filename +".pdf"

x_min, y_min, total_x_size, total_y_size = ImageSize(files)

file_list, total_x_size, total_y_size, x_min, y_min = ResizeToMin(files, x_min, y_min, total_x_size, total_y_size)

ImageMerge(file_list, total_x_size, total_y_size, x_min, y_min)
