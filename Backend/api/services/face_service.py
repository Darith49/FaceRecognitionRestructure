import os
import logging
import numpy as np
from django.core.files.storage import default_storage

logger = logging.getLogger(__name__)

# ArcFace cosine distance threshold (lower = stricter match)
MATCH_THRESHOLD = 0.45


class FaceService:
    @staticmethod
    def save_temp_file(uploaded_file, prefix="face"):
        """Saves an uploaded image to temporary disk storage and returns (file_name, full_path)."""
        file_name = default_storage.save(f'{prefix}_{uploaded_file.name}', uploaded_file)
        full_path = default_storage.path(file_name)
        return file_name, full_path

    @staticmethod
    def cleanup_file(file_name):
        """Safely deletes a temporary uploaded file from disk."""
        try:
            full_path = default_storage.path(file_name)
            if os.path.exists(full_path):
                default_storage.delete(file_name)
        except Exception as e:
            logger.warning("Failed to clean up temp file %s: %s", file_name, e)

    @staticmethod
    def extract_embedding(image_path: str):
        """
        Extracts a 512-dim face embedding vector using DeepFace with ArcFace and MTCNN.
        Returns list of floats or None if no face is detected.
        """
        try:
            from deepface import DeepFace

            results = DeepFace.represent(
                img_path=image_path,
                model_name="ArcFace",
                detector_backend="mtcnn",
                enforce_detection=True,
            )
            if results and len(results) > 0:
                return results[0]["embedding"]
            return None
        except Exception as e:
            logger.error("[FaceService.extract_embedding] error: %s", e)
            return None

    @staticmethod
    def compare_embeddings(embedding_a, embedding_b, threshold=MATCH_THRESHOLD):
        """
        Computes cosine distance between two embedding vectors.
        Returns (distance, confidence, is_match).
        """
        a = np.array(embedding_a, dtype=np.float32)
        b = np.array(embedding_b, dtype=np.float32)

        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)

        if norm_a == 0 or norm_b == 0:
            return 1.0, 0.0, False

        cosine_similarity = np.dot(a, b) / (norm_a * norm_b)
        distance = float(1.0 - cosine_similarity)
        confidence = round(max(0.0, (1.0 - distance)) * 100, 1)
        is_match = distance <= threshold

        return distance, confidence, is_match
