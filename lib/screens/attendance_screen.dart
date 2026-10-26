import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  // قائمة المدرسين والتخصصات
  final List<String> _teachersList = [
    "أحمد خليل إبراهيم",
    "محمود جاسم محمد",
    "عمر فاروق علي",
    "حسن حسين علي",
    "خالد وليد إسماعيل",
    "مصطفى طه ياسين",
    "عبدالله يونس أحمد",
  ];

  final List<String> _specialtiesList = [
    "التربية الإسلامية",
    "اللغة العربية",
    "اللغة الإنكليزية",
    "الرياضيات",
    "الفيزياء",
    "الكيمياء",
    "الأحياء",
    "الاجتماعيات",
    "التربية الرياضية",
  ];

  String? _selectedTeacher;
  String? _selectedSpecialty;
  String _recordType = "حضور"; // حضور أو انصراف

  // إحداثيات رسم التوقيع (Pure Dart Custom Painter)
  List<Offset?> _signaturePoints = [];

  // بيانات الحفظ والمراجعة
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isBypassTimeGate = false; // خيار إداري للتجربة في أي وقت

  @override
  void initState() {
    super.initState();
    _loadSavedRecords();
  }

  // تحميل السجلات القديمة المخزنة
  Future<void> _loadSavedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('teachers_attendance_logs');
    if (data != null) {
      setState(() {
        _attendanceHistory = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  // حفظ سجل جديد محلياً
  Future<void> _saveRecord() async {
    if (_selectedTeacher == null || _selectedSpecialty == null) {
      _showSnackBar("يرجى اختيار اسم المدرس والتخصص أولاً", Colors.orangeAccent);
      return;
    }

    if (_signaturePoints.isEmpty) {
      _showSnackBar("يرجى توقيع المدرس في المربع الأبيض قبل الحفظ", Colors.orangeAccent);
      return;
    }

    // فحص وقت الدوام بتوقيت العراق (UTC+3)
    if (!_isTimeGateOpen() && !_isBypassTimeGate) {
      _showSnackBar("النظام مغلق حالياً! التسجيل متاح فقط في أوقات الدوام الرسمية", Colors.redAccent);
      return;
    }

    final now = DateTime.now();
    final record = {
      "id": now.millisecondsSinceEpoch.toString(),
      "teacher": _selectedTeacher,
      "specialty": _selectedSpecialty,
      "type": _recordType,
      "date": DateFormat('yyyy-MM-dd').format(now),
      "time": DateFormat('hh:mm:ss a').format(now),
      "hasSignature": true,
    };

    _attendanceHistory.insert(0, record);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teachers_attendance_logs', json.encode(_attendanceHistory));

    _showSnackBar("تم تسجيل ${_recordType} المدرس بنجاح وحفظ البيانات", Colors.greenAccent);

    // إعادة تعيين الحقول
    setState(() {
      _signaturePoints.clear();
      _selectedTeacher = null;
      _selectedSpecialty = null;
    });
  }

  // فحص أوقات فتح النظام (08:00 - 09:00 ص) و (11:00 - 12:30 م) بتوقيت العراق
  bool _isTimeGateOpen() {
    final iraqTime = DateTime.now().toUtc().add(const Duration(hours: 3));
    final minutes = iraqTime.hour * 60 + iraqTime.minute;

    // الفترة الأولى: 08:00 ص (480 دقيقة) إلى 09:00 ص (540 دقيقة) -> حضور
    final isMorningWindow = minutes >= 480 && minutes <= 540;

    // الفترة الثانية: 11:00 ص (660 دقيقة) إلى 12:30 م (750 دقيقة) -> انصراف
    final isAfternoonWindow = minutes >= 660 && minutes <= 750;

    return isMorningWindow || isAfternoonWindow;
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: color.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystemOpen = _isTimeGateOpen() || _isBypassTimeGate;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0284C7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. الشريط العلوي والحالة الزمنية
              _buildTopBar(isSystemOpen),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. نوع التسجيل (حضور / انصراف)
                      _buildTypeSegment(),

                      const SizedBox(height: 16),

                      // 3. القائمة المنسدلة لاسم المدرس
                      _buildGlassLabel("اسم المدرس المحترم:"),
                      const SizedBox(height: 6),
                      _buildTeacherDropdown(),

                      const SizedBox(height: 16),

                      // 4. القائمة المنسدلة للتخصص
                      _buildGlassLabel("المادة / الاختصاص:"),
                      const SizedBox(height: 6),
                      _buildSpecialtyDropdown(),

                      const SizedBox(height: 20),

                      // 5. مربع التوقيع الأبيض
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlassLabel("توقيع المدرس (في المربع الأبيض):"),
                          TextButton.icon(
                            onPressed: () => setState(() => _signaturePoints.clear()),
                            icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
                            label: const Text("مسح التوقيع", style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildSignaturePad(),

                      const SizedBox(height: 24),

                      // 6. زر الحفظ الدائري الزجاجي
                      Center(child: _buildCircularSaveButton()),

                      const SizedBox(height: 30),

                      // 7. أدوات الأرشيف والتصدير
                      _buildExportAndArchiveSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الهيدر والبوابة الزمنية
  Widget _buildTopBar(bool isOpen) {
    return _buildGlassContainer(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.lock_open_outlined : Icons.lock_clock,
            color: isOpen ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "إعدادية البعاج للبنين",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                ),
                Text(
                  isOpen ? "النظام مفتوح لاستقبال التواقيع" : "مغلق (ساعات الدوام: 08-09ص / 11-12:30م)",
                  style: TextStyle(color: isOpen ? Colors.greenAccent : Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          // زر التجاوز الإداري لتجربة التطبيق خارج الوقت الرسمي
          IconButton(
            icon: Icon(_isBypassTimeGate ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined, color: Colors.white70),
            onPressed: () => setState(() => _isBypassTimeGate = !_isBypassTimeGate),
            tooltip: "تفعيل الوضع الاختباري",
          ),
        ],
      ),
    );
  }

  // مفتاح الاختيار بين الحضور والانصراف
  Widget _buildTypeSegment() {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recordType = "حضور"),
              child: Container(
                padding: const EdgeInsets.vertical(10),
                decoration: BoxDecoration(
                  color: _recordType == "حضور" ? Colors.greenAccent.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _recordType == "حضور" ? Border.all(color: Colors.greenAccent) : null,
                ),
                child: const Center(
                  child: Text("تسجيل حضور (صباحاً)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recordType = "انصراف"),
              child: Container(
                padding: const EdgeInsets.vertical(10),
                decoration: BoxDecoration(
                  color: _recordType == "انصراف" ? Colors.orangeAccent.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _recordType == "انصراف" ? Border.all(color: Colors.orangeAccent) : null,
                ),
                child: const Center(
                  child: Text("تسجيل انصراف (ظهراً)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // قائمة المدرسين المنسدلة الزجاجية
  Widget _buildTeacherDropdown() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTeacher,
          hint: const Text("اختر اسم المدرس من القائمة...", style: TextStyle(color: Colors.white60, fontFamily: 'Cairo')),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: _teachersList.map((String name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedTeacher = val),
        ),
      ),
    );
  }

  // قائمة التخصصات المنسدلة الزجاجية
  Widget _buildSpecialtyDropdown() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSpecialty,
          hint: const Text("اختر اختصاص المدرس...", style: TextStyle(color: Colors.white60, fontFamily: 'Cairo')),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: _specialtiesList.map((String spec) {
            return DropdownMenuItem<String>(
              value: spec,
              child: Text(spec, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSpecialty = val),
        ),
      ),
    );
  }

  // مربع التوقيع التفاعلي بخلفية بيضاء
  Widget _buildSignaturePad() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              _signaturePoints.add(renderBox.globalToLocal(details.globalPosition));
            });
          },
          onPanEnd: (DragEndDetails details) {
            _signaturePoints.add(null);
          },
          child: CustomPaint(
            painter: SignaturePainter(_signaturePoints),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  // زر الحفظ الزجاجي الدائري
  Widget _buildCircularSaveButton() {
    return GestureDetector(
      onTap: _saveRecord,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.save_outlined,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  // قسم الأرشيف وتصدير ملفات PDF و Excel
  Widget _buildExportAndArchiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassLabel("سجل السجلات المحفوظة والتصدير:"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showSnackBar("جاري تجهيز وتصدير كشف المدرسين بصيغة Excel...", Colors.green),
                icon: const Icon(Icons.table_chart, color: Colors.white),
                label: const Text("تصدير Excel", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showSnackBar("جاري تجهيز طباعة السجل بصيغة PDF...", Colors.red),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("تصدير PDF", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // عرض السجلات المخزنة القديمة
        Text(
          "السجلات المخزنة بالسيرفر المحلي (${_attendanceHistory.length} سجل)",
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attendanceHistory.length > 5 ? 5 : _attendanceHistory.length,
          itemBuilder: (context, index) {
            final item = _attendanceHistory[index];
            return _buildGlassContainer(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    item['type'] == 'حضور' ? Icons.check_circle : Icons.logout,
                    color: item['type'] == 'حضور' ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item['teacher']} (${item['specialty']})",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        Text(
                          "${item['type']} - التاريخ: ${item['date']} | الوقت: ${item['time']}",
                          style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlassLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// كلاس رسم التوقيع باللمس التفاعلي
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}