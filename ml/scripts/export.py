import os
import tensorflow as tf

def export_to_tflite(modality, data_dir, model_dir):
    print(f"--- Exporting {modality} to TFLite INT8 ---")
    keras_model_path = os.path.join(model_dir, f"{modality}_model.keras")
    tflite_model_path = os.path.join(model_dir, f"{modality}_model.tflite")
    
    if not os.path.exists(keras_model_path):
        print(f"Model {keras_model_path} does not exist.")
        return
        
    model = tf.keras.models.load_model(keras_model_path)
    
    # Representative dataset generator for INT8 quantization
    modality_dir = os.path.join(data_dir, modality)
    val_ds = tf.keras.utils.image_dataset_from_directory(
        modality_dir,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=(224, 224),
        batch_size=1
    )
    
    def representative_data_gen():
        for input_value, _ in val_ds.take(100):
            yield [input_value]

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_data_gen
    
    # Ensure fully INT8
    # converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    # converter.inference_input_type = tf.int8
    # converter.inference_output_type = tf.int8
    
    tflite_quant_model = converter.convert()
    
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_quant_model)
        
    print(f"Saved {tflite_model_path}")

    # Test inference
    interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Take one sample
    for images, labels in val_ds.take(1):
        interpreter.set_tensor(input_details[0]['index'], images)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        print(f"Sample prediction: {output_data}, true label: {labels.numpy()}")

if __name__ == "__main__":
    data_dir = r"d:\Projects\HemLens\ml\data"
    model_dir = r"d:\Projects\HemLens\ml\models"
    for m in ['conjunctiva', 'fingernail', 'palm']:
        export_to_tflite(m, data_dir, model_dir)
