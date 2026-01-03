import cv2
import imagehash
from PIL import Image

def compute_image_hash(img):
    pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    return str(imagehash.phash(pil_img))
