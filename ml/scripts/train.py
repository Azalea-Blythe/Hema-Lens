import os
import argparse
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2 # type: ignore
from tensorflow.keras.models import Model # type: ignore
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout # type: ignore
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix
import numpy as np

def build_model(num_classes=3):
    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    base_model.trainable = False
    
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.2)(x)
    predictions = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=predictions)
    # Use metrics string since 'accuracy' is available built-in
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    return model

def train_and_evaluate(modality, data_dir, model_out_dir, epochs=5, batch_size=32):
    print(f"--- Training model for {modality} ---")
    modality_dir = os.path.join(data_dir, modality)
    
    if not os.path.exists(modality_dir):
        print(f"Directory {modality_dir} does not exist. Skipping.")
        return
        
    train_ds = tf.keras.utils.image_dataset_from_directory(
        modality_dir,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=(224, 224),
        batch_size=batch_size
    )
    
    val_ds = tf.keras.utils.image_dataset_from_directory(
        modality_dir,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=(224, 224),
        batch_size=batch_size
    )
    
    class_names = train_ds.class_names
    num_classes = len(class_names)
    print("Classes:", class_names)
    
    # AUTOTUNE
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)
    
    model = build_model(num_classes=num_classes)
    
    # Early stopping callback
    es = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=2, restore_best_weights=True)
    
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs,
        callbacks=[es]
    )
    
    # Evaluate
    print(f"--- Evaluating {modality} ---")
    y_true = []
    y_pred = []
    
    for images, labels in val_ds:
        preds = model.predict(images, verbose=0)
        y_pred.extend(np.argmax(preds, axis=1))
        y_true.extend(labels.numpy())
        
    acc = accuracy_score(y_true, y_pred)
    f1 = f1_score(y_true, y_pred, average='weighted')
    cm = confusion_matrix(y_true, y_pred)
    
    print(f"Accuracy: {acc:.4f}")
    print(f"F1 Score (Weighted): {f1:.4f}")
    print("Confusion Matrix:")
    print(cm)
    
    # Save keras model inside out dir
    os.makedirs(model_out_dir, exist_ok=True)
    model_path = os.path.join(model_out_dir, f"{modality}_model.keras")
    model.save(model_path)
    print(f"Saved to {model_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--modality', type=str, default='all', choices=['all', 'conjunctiva', 'fingernail', 'palm'])
    parser.add_argument('--epochs', type=int, default=5)
    parser.add_argument('--batch_size', type=int, default=32)
    args = parser.parse_args()
    
    data_dir = r"d:\Projects\HemLens\ml\data"
    model_out_dir = r"d:\Projects\HemLens\ml\models"
    
    modalities = ['conjunctiva', 'fingernail', 'palm'] if args.modality == 'all' else [args.modality]
    for m in modalities:
        train_and_evaluate(m, data_dir, model_out_dir, epochs=args.epochs, batch_size=args.batch_size)
