import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  File? _selectedImageFile;
  String label = "";
  double confidence = 0.0;

  // Fungsi untuk menginisialisasi model TensorFlow Lite (TFLite).
  Future<void> _tfLteInit() async {
    await Tflite.loadModel(
      model:
          "gambar/plant_modelH5_16.tflite", // Lokasi file model TFLite di dalam folder gambar.
      labels:
          "assets/label.txt", // Lokasi file label yang digunakan untuk mengklasifikasikan hasil prediksi.
      // numThreads:
      //     1, // Menentukan jumlah thread yang digunakan untuk pemrosesan (default adalah 1).
      // isAsset:
      //     true, // Menentukan apakah model diambil dari folder assets (default adalah true).
      // useGpuDelegate:
      //     false // Menentukan apakah akan menggunakan GPU untuk pemrosesan (default adalah false).
    );
  }

  @override
  void initState() {
    _tfLteInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C2B2B),
        centerTitle: true,
        title: const Text(
          'Aplikasi Klasifikasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey,
                margin: const EdgeInsets.all(16),
                child: _selectedImageFile != null
                    ? Image.file(_selectedImageFile!)
                    : const Icon(
                        Icons.image,
                      ),
              ),
              Text(
                label,
              ),
              Text(
                "Akurasi ${confidence.toStringAsFixed(0)}%",
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _onPickPhoto(
                  ImageSource.gallery,
                ),
                child: const Text(
                  'Gallery',
                ),
              ),
              ElevatedButton(
                onPressed: () => _onPickPhoto(
                  ImageSource.camera,
                ),
                child: const Text(
                  'Camera',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Fungsi untuk mengambil foto dari sumber yang ditentukan (kamera atau galeri).
  void _onPickPhoto(ImageSource source) async {
    // Menggunakan ImagePicker untuk memilih gambar dari sumber yang dipilih.
    final pickedFile = await picker.pickImage(source: source);

    // Jika tidak ada file gambar yang dipilih, keluar dari fungsi.
    if (pickedFile == null) {
      return;
    }

    // Mengonversi file yang dipilih ke dalam format File menggunakan path-nya.
    final imageFile = File(pickedFile.path);

    // Memperbarui state dengan file gambar yang dipilih agar dapat ditampilkan di UI.
    setState(() {
      _selectedImageFile = imageFile;
    });

    // Menjalankan model TFLite pada gambar yang dipilih.
    var recognitions = await Tflite.runModelOnImage(
        path:
            pickedFile.path, // Path gambar yang akan dianalisis (wajib diisi).
        imageMean: 0.0, // Nilai rata-rata normalisasi gambar (default: 117.0).
        imageStd: 1.0, // Standar deviasi normalisasi gambar (default: 1.0).
        numResults:
            5, // Jumlah hasil prediksi maksimal yang diambil (default: 5).
        threshold:
            0.1, // Ambang batas kepercayaan minimal untuk prediksi (default: 0.1).
        asynch:
            true // Menentukan apakah proses dilakukan secara asinkron (default: true).
        );

    // Jika hasil pengenalan (recognitions) kosong, tampilkan log dan keluar dari fungsi.
    if (recognitions == null) {
      print("recognitions is Null");
      return;
    }

    // Menampilkan hasil pengenalan ke konsol.
    print(recognitions.toString());

    // Memperbarui state untuk menyimpan tingkat kepercayaan dan label prediksi.
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100); // Konversi ke persen.
      label = recognitions[0]['label'].toString(); // Label prediksi pertama.
    });
  }
}
