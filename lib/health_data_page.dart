import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({Key? key}) : super(key: key);

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  String? gender;
  int birthYear = 2000;
  String heightUnit = 'cm';
  double height = 170;
  double weight = 70;
  String activityLevel = 'Not active';
  int currentStep = 0;


  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final userData = await _firestoreService.getUserPersonalization();
      if (userData != null) {
        setState(() {
          gender = userData['gender'];
          birthYear = userData['birthYear'];
          height = userData['height'];
          weight = userData['weight'];
          activityLevel = userData['activityLevel'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Health Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDataItem('Sex', gender ?? 'Not set', _editSex),
                      _buildDataItem('Year of Birth', birthYear?.toString() ?? 'Not set', _editYearOfBirth),
                      _buildDataItem('Height', height != null ? '$height cm' : 'Not set', _editHeight),
                      _buildDataItem('Weight', weight != null ? '$weight kg' : 'Not set', _editWeight),
                      _buildDataItem('Activity Level', activityLevel ?? 'Not set', _editActivityLevel),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _saveHealthData,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}

  Widget _buildDataItem(String label, String value, VoidCallback onEdit) {
    return Column(
      children: [
        ListTile(
          title: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
        const Divider(
          color: Colors.grey,
          height: 1,
        ),
      ],
    );
  }

  Widget _buildField(String label, String value, VoidCallback onTap) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 37, 37, 37),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.red, size: 23),
                    onPressed: onTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(
          color: Colors.black,
          height: 3,
          indent: 0,
          endIndent: 0,
        ),
      ],
    );
  }

  Future<void> _saveHealthData() async {
  setState(() => isLoading = true);
  try {
    await _firestoreService.saveUserPersonalization({
      'gender': gender,
      'birthYear': birthYear,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health data saved successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving health data: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  void _editSex() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomGenderPicker(
          initialValue: gender,
        ),
      ),
    ).then((selectedGender) {
      if (selectedGender != null) {
        setState(() {
          gender = selectedGender;
        });
      }
    });
  }

  void _editYearOfBirth() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: birthYear.toDouble(),
          minValue: 1900,
          maxValue: 2045,
          onValueChanged: (value) {
            setState(() => birthYear = value.toInt());
          },
        ),
      ),
    );
  }

  void _editHeight() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your height',
          unit: 'cm',
          initialValue: height,
          minValue: 100,
          maxValue: 250,
          onValueChanged: (value) {
            setState(() => height = value);
          },
        ),
      ),
    );
  }

  void _editWeight() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: weight,
          minValue: 30,
          maxValue: 200,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => weight = value);
          },
        ),
      ),
    );
  }

  void _editActivityLevel() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomActivityLevelPicker(
          initialValue: activityLevel,
        ),
      ),
    ).then((selectedActivityLevel) {
      if (selectedActivityLevel != null) {
        setState(() {
          activityLevel = selectedActivityLevel;
        });
      }
    });
  }
} 