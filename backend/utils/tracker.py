# backend/anpr/tracker.py
# Minimal SORT tracker (works for YOLO detections)

import numpy as np
from scipy.optimize import linear_sum_assignment
from filterpy.kalman import KalmanFilter


def iou(bb_test, bb_gt):
    xx1 = max(bb_test[0], bb_gt[0])
    yy1 = max(bb_test[1], bb_gt[1])
    xx2 = min(bb_test[2], bb_gt[2])
    yy2 = min(bb_test[3], bb_gt[3])

    w = max(0., xx2 - xx1)
    h = max(0., yy2 - yy1)
    wh = w * h

    o = wh / (
        (bb_test[2] - bb_test[0]) * (bb_test[3] - bb_test[1]) +
        (bb_gt[2] - bb_gt[0]) * (bb_gt[3] - bb_gt[1]) - wh
    )
    return o


class KalmanBoxTracker:
    count = 0

    def __init__(self, bbox):
        self.kf = KalmanFilter(dim_x=7, dim_z=4)
        self.kf.F = np.array([
            [1, 0, 0, 0, 1, 0, 0],
            [0, 1, 0, 0, 0, 1, 0],
            [0, 0, 1, 0, 0, 0, 1],
            [0, 0, 0, 1, 0, 0, 0],
            [0, 0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 0, 1]
        ])
        self.kf.H = np.array([
            [1, 0, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0, 0],
            [0, 0, 0, 1, 0, 0, 0]
        ])

        self.kf.x[:4] = bbox.reshape((4, 1))
        self.time_since_update = 0
        self.id = KalmanBoxTracker.count
        KalmanBoxTracker.count += 1

    def update(self, bbox):
        self.time_since_update = 0
        self.kf.update(bbox)

    def predict(self):
        self.kf.predict()
        self.time_since_update += 1
        return self.kf.x[:4].reshape(-1)

    def get_state(self):
        return self.kf.x[:4].reshape(-1)


class Sort:
    def __init__(self, max_age=10, iou_threshold=0.3):
        self.trackers = []
        self.max_age = max_age
        self.iou_threshold = iou_threshold

    def update(self, detections):
        if len(detections) == 0:
            return np.empty((0, 5))

        dets = np.array(detections)
        trks = np.array([t.predict() for t in self.trackers])

        iou_matrix = np.zeros((len(dets), len(trks)))
        for d, det in enumerate(dets):
            for t, trk in enumerate(trks):
                iou_matrix[d, t] = iou(det, trk)

        matched_indices = linear_sum_assignment(-iou_matrix)
        matched_indices = np.array(list(zip(*matched_indices)))

        unmatched_dets = set(range(len(dets)))
        unmatched_trks = set(range(len(trks)))

        for d, t in matched_indices:
            if iou_matrix[d, t] < self.iou_threshold:
                continue
            self.trackers[t].update(dets[d][:4])
            unmatched_dets.discard(d)
            unmatched_trks.discard(t)

        for i in unmatched_dets:
            self.trackers.append(KalmanBoxTracker(dets[i][:4]))

        results = []
        for t in self.trackers[:]:
            if t.time_since_update > self.max_age:
                self.trackers.remove(t)
            else:
                x1, y1, x2, y2 = t.get_state()
                results.append([x1, y1, x2, y2, t.id])

        return np.array(results)
