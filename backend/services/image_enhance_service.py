import cv2
import numpy as np

# ---------------------------
# Image Enhancement Functions
# ---------------------------

def denoise_image(img, method="bilateral"):
    if method == "median":
        return cv2.medianBlur(img, 5)
    elif method == "bilateral":
        return cv2.bilateralFilter(img, 9, 75, 75)
    return img


def deblur_image(img, strength=1.5):
    blur = cv2.GaussianBlur(img, (0, 0), sigmaX=1.0)
    sharpened = cv2.addWeighted(img, strength, blur, -0.5, 0)
    return sharpened


def low_light_boost(img, gamma=1.5):
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l = clahe.apply(l)

    lab = cv2.merge((l, a, b))
    enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

    inv_gamma = 1.0 / gamma
    table = np.array(
        [(i / 255.0) ** inv_gamma * 255 for i in range(256)]
    ).astype("uint8")

    return cv2.LUT(enhanced, table)


def colorize_image(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray_3 = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

    hsv = cv2.cvtColor(gray_3, cv2.COLOR_BGR2HSV)
    hsv[..., 1] = 80   # saturation
    hsv[..., 2] = 200  # brightness

    return cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)


# ---------------------------
# Main Enhancement Pipeline
# ---------------------------

def enhance_image_pipeline(
    img,
    apply_denoise=False,
    apply_deblur=False,
    apply_low_light=False,
    apply_colorize=False
):
    output = img.copy()

    if apply_denoise:
        output = denoise_image(output)

    if apply_deblur:
        output = deblur_image(output)

    if apply_low_light:
        output = low_light_boost(output)

    if apply_colorize:
        output = colorize_image(output)

    return output
