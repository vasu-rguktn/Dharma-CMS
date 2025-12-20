import cv2, numpy as np
from utils.file_utils import read_image, save_temp_image
from utils.image_utils import denoise, deblur, low_light_boost, upscale

def enhance_image(file, denoise_f, deblur_f, low_light_f, upscale_f):
    img = read_image(file)

    if denoise_f:
        img = denoise(img)
    if deblur_f:
        img = deblur(img)
    if low_light_f:
        img = low_light_boost(img)
    if upscale_f:
        img = upscale(img)

    path = save_temp_image(img)
    return {"status": "success", "output_path": path}
