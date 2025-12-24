import cv2
from utils.file_utils import read_image, save_temp_image

face_net = cv2.dnn.readNetFromCaffe(
    "models/face_models/deploy.prototxt",
    "models/face_models/res10_300x300_ssd.caffemodel"
)

def detect_faces(file):
    img = read_image(file)
    h, w = img.shape[:2]

    blob = cv2.dnn.blobFromImage(img, 1.0, (300,300))
    face_net.setInput(blob)
    detections = face_net.forward()

    faces = []
    for i in range(detections.shape[2]):
        conf = detections[0,0,i,2]
        if conf > 0.6:
            box = detections[0,0,i,3:7] * [w,h,w,h]
            x1,y1,x2,y2 = box.astype(int)
            crop = img[y1:y2, x1:x2]
            path = save_temp_image(crop)
            faces.append({"bbox":[x1,y1,x2,y2], "path":path})

    return {"faces": faces}
