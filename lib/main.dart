import 'package:flutter/material.dart';
// ใช้สร้างหน้าจอ ปุ่ม กล่องข้อความ ต่าง ๆ ในแอป

import 'firebase_options.dart';
// ไฟล์นี้เป็นไฟล์ตั้งค่าของ Firebase
// บอกว่าแอปนี้จะไปใช้ Firebase โปรเจกต์ไหน

import 'package:firebase_core/firebase_core.dart';
// ใช้เปิดการใช้งาน Firebase

import 'package:cloud_firestore/cloud_firestore.dart';
// ใช้ติดต่อกับ Firestore (ฐานข้อมูลของ Firebase)


// =======================
// จุดเริ่มต้นของแอป
// =======================
void main() async {

  // บอก Flutter ว่าเราจะใช้คำสั่ง async
  WidgetsFlutterBinding.ensureInitialized();

  // เปิดการใช้งาน Firebase
  // ถ้าไม่เขียนอันนี้ จะเพิ่ม / ดึงข้อมูลไม่ได้
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // เปิดแอป
  runApp(const MyApp());
}


// =======================
// ตัวแอปหลัก
// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // MaterialApp คือโครงหลักของแอป
    return MaterialApp(
      title: 'Song App',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Song Management'),
    );
  }
}


// =======================
// หน้าแรกของแอป
// =======================
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


// =======================
// ตัวควบคุมการทำงานของหน้าแรก
// =======================
class _MyHomePageState extends State<MyHomePage> {

  // Controller คือกล่องไว้เก็บค่าที่ผู้ใช้พิมพ์
  // เช่น พิมพ์ชื่อเพลง → ค่าจะมาอยู่ตรงนี้
  final TextEditingController _songNameCtrl = TextEditingController();
  final TextEditingController _artistCtrl = TextEditingController();
  final TextEditingController _songTypeCtrl = TextEditingController();


  // =======================
  // ฟังก์ชันเพิ่มข้อมูลเพลง
  // =======================
  void addSong() async {

    // เอาข้อมูลที่ผู้ใช้พิมพ์ออกมาจาก TextField
    String songName = _songNameCtrl.text;
    String artist = _artistCtrl.text;
    String songType = _songTypeCtrl.text;

    try {
      // เอาข้อมูลไปเก็บใน Firebase Firestore
      // songs = ชื่อที่เก็บข้อมูล (collection)
      await FirebaseFirestore.instance
          .collection("songs")
          .add({
        "songName": songName,
        "artist": artist,
        "songType": songType,
      });

      // พอเพิ่มเสร็จ ล้างช่องกรอกให้ว่าง
      _songNameCtrl.clear();
      _artistCtrl.clear();
      _songTypeCtrl.clear();

    } catch (e) {
      // ถ้าเพิ่มข้อมูลไม่ได้
      print("เกิดข้อผิดพลาด: $e");
    }
  }


  // =======================
  // ส่วนแสดงหน้าจอ
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ช่องพิมพ์ชื่อเพลง
            TextField(
              controller: _songNameCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อเพลง",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ช่องพิมพ์ชื่อศิลปิน
            TextField(
              controller: _artistCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อศิลปิน",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ช่องพิมพ์ประเภทเพลง
            TextField(
              controller: _songTypeCtrl,
              decoration: const InputDecoration(
                labelText: "ประเภทเพลง",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // ปุ่มเพิ่มเพลง
            ElevatedButton(
              onPressed: addSong, // กดแล้วเรียกฟังก์ชัน addSong
              child: const Text("เพิ่มเพลง"),
            ),

            const SizedBox(height: 15),


            // =======================
            // ดึงข้อมูลจาก Firebase มาแสดง
            // =======================
            Expanded(
              child: StreamBuilder(

                // snapshots() คือดึงข้อมูลแบบสด
                // เพิ่มข้อมูลใหม่ → หน้าจอเปลี่ยนทันที
                stream: FirebaseFirestore.instance
                    .collection("songs")
                    .snapshots(),

                builder: (context, snapshot) {

                  // ระหว่างโหลดข้อมูล
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // ถ้าเกิดปัญหา
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }

                  // เอาข้อมูลทั้งหมดออกมาจาก Firebase
                  final docs = snapshot.data!.docs;

                  // แสดงข้อมูลออกมาเป็นตาราง
                  return GridView.builder(
                    itemCount: docs.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {

                      // ข้อมูลเพลงแต่ละอัน
                      final song = docs[index].data();

                      return Card(
                        child: Center(
                          child: Text(
                            song["songName"], // แสดงชื่อเพลง
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}