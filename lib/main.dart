import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// =======================
/// ฟังก์ชันเริ่มต้นแอป
/// =======================
void main() async {
  // ผูก Flutter กับ engine (จำเป็นก่อนใช้ async)
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // เรียกแอปหลัก
  runApp(const MyApp());
}

/// =======================
/// Widget หลักของแอป
/// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song App',
      debugShowCheckedModeBanner: false, // เอาแถบ debug ออก
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Song Management'),
    );
  }
}

/// =======================
/// หน้าแรก (Stateful)
/// =======================
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// =======================
/// State ของหน้าแรก
/// =======================
class _MyHomePageState extends State<MyHomePage> {
  // Controller สำหรับรับค่าจาก TextField
  final TextEditingController _songNameCtrl = TextEditingController();
  final TextEditingController _artistCtrl = TextEditingController();
  final TextEditingController _songTypeCtrl = TextEditingController();

  /// =======================
  /// ฟังก์ชันเพิ่มข้อมูลเพลง
  /// =======================
  void addSong() async {
    // ดึงค่าจากช่องกรอก
    String songName = _songNameCtrl.text;
    String artist = _artistCtrl.text;
    String songType = _songTypeCtrl.text;

    try {
      // บันทึกข้อมูลลง Firestore
      await FirebaseFirestore.instance.collection("songs").add({
        "songName": songName,
        "artist": artist,
        "songType": songType,
      });

      // ล้างช่องกรอกหลังบันทึกเสร็จ
      _songNameCtrl.clear();
      _artistCtrl.clear();
      _songTypeCtrl.clear();
    } catch (e) {
      // แสดง error กรณีบันทึกไม่สำเร็จ
      print("เกิดข้อผิดพลาด: $e");
    }
  }

  /// =======================
  /// ส่วน UI หลัก
  /// =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// ===== ช่องกรอกชื่อเพลง =====
            TextField(
              controller: _songNameCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อเพลง",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            /// ===== ช่องกรอกศิลปิน =====
            TextField(
              controller: _artistCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อศิลปิน",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            /// ===== ช่องกรอกประเภทเพลง =====
            TextField(
              controller: _songTypeCtrl,
              decoration: const InputDecoration(
                labelText: "ประเภทเพลง",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            /// ===== ปุ่มเพิ่มเพลง =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addSong,
                child: const Text("เพิ่มเพลง"),
              ),
            ),
            const SizedBox(height: 15),

            /// ===== แสดงรายการเพลงจาก Firestore =====
            Expanded(
              child: StreamBuilder(
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

                  // ถ้ามี error
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }

                  // ดึงเอกสารทั้งหมด
                  final docs = snapshot.data!.docs;

                  // แสดงข้อมูลแบบ Grid
                  return GridView.builder(
                    itemCount: docs.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final song = docs[index].data();

                      return InkWell(
                        onTap: () {
                          // ไปหน้ารายละเอียดเพลง
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SongDetail(song: song),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          child: Center(
                            child: Text(
                              song["songName"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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

/// =======================
/// หน้ารายละเอียดเพลง
/// =======================
class SongDetail extends StatelessWidget {
  final Map<String, dynamic> song;

  const SongDetail({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายละเอียดเพลง")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ชื่อเพลง: ${song["songName"]}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("ศิลปิน: ${song["artist"]}"),
            const SizedBox(height: 8),
            Text("ประเภทเพลง: ${song["songType"]}"),
          ],
        ),
      ),
    );
  }
}
