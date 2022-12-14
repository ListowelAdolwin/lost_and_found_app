import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/src/authentification/cubit/user_cubit.dart';
import 'package:lost_and_found/src/services/objet_service.dart';
import 'package:lost_and_found/src/utils/app_button.dart';
import 'package:lost_and_found/src/utils/app_colors.dart';
import 'package:lost_and_found/src/utils/app_input.dart';

class AddLostObjetPage extends StatefulWidget {
  const AddLostObjetPage({Key? key}) : super(key: key);

  @override
  _AddLostObjetPageState createState() => _AddLostObjetPageState();
}

class _AddLostObjetPageState extends State<AddLostObjetPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream;
  String? selectedCategory;
  late User? user;

  XFile? image;
  String? imageUrl;
  late Objetservice _objetservice;
  String? error;
  bool? isLoading;

  Future getData() async {
    Map<String, dynamic> data = {};
    data['title'] = _titleController.text;
    data['description'] = _descController.text;
    data['user_id'] = user!.uid;
    data['category_id'] = selectedCategory!;
    return data;
  }

  @override
  void initState() {
    _titleController = TextEditingController();
    _descController = TextEditingController();
    categoriesStream =
        FirebaseFirestore.instance.collection("categories").snapshots();

    _objetservice = Objetservice();

    user = FirebaseAuth.instance.currentUser;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeigth = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          //context.read<UserCubit>().getAuthenticatedUser(user!.uid);
          print(state.copyWith().user);
          if (state is UserInitial) {
            context.read<UserCubit>().getAuthenticatedUser(user!.uid);
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            autovalidateMode: AutovalidateMode.disabled,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RichText(
                        text: const TextSpan(
                          text: "Found",
                          style: TextStyle(
                              fontSize: 30,
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700),
                          children: [
                            TextSpan(
                              text: " Something ?",
                              style: TextStyle(
                                fontSize: 30,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenwidth * 0.01,
                  ),
                  StreamBuilder(
                    stream: categoriesStream,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      if (snapshot.hasData) {
                        List<QueryDocumentSnapshot<Object?>> cats =
                            snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          onChanged: (value) {
                            selectedCategory = value;
                            setState(() {});
                          },
                          hint: const Text("Select category"),
                          value: selectedCategory,
                          items: cats.map((e) {
                            var cat = e.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              child: Text("${cat['title']}"),
                              value: cat['id'],
                            );
                          }).toList(),
                        );
                      }
                      return Container();
                    },
                  ),
                  AppInput(
                    controller: _titleController,
                    label: "Title",
                    validator: (value) {
                      return "Please enter title";
                    },
                  ),
                  AppInput(
                    controller: _descController,
                    label: "Description",
                    validator: (value) {
                      return "Please enter Description";
                    },
                    maxLines: 5,
                  ),
                  SizedBox(
                    height: screenwidth * 0.02,
                  ),
                  Container(
                    width: double.infinity,
                    height: screenHeigth * .28,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black26,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (image == null)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.2),
                            ),
                          ),
                        if (image != null)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.2),
                              image: DecorationImage(
                                image: FileImage(
                                  File(image!.path),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: GestureDetector(
                            onTap: () async {
                              final ImagePicker _picker = ImagePicker();
                              final XFile? img = await _picker.pickImage(
                                  source: ImageSource.gallery);
                              if (img != null) {
                                setState(() {
                                  image = img;
                                });
                              }
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.add_a_photo,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: screenwidth * 0.01,
                  ),
                  if (isLoading == true)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  if (error != null)
                    Center(
                      child: Text(error!),
                    ),
                  AppButton(
                    text: "Send",
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                        error = null;
                      });

                      var data = await getData();
                      data['user_id'] = state.user!.uid;
                      data['user_name'] = state.user!.name;
                      data['user_subname'] = state.user!.subname;
                      data['user_email'] = state.user!.email;
                      data['user_tel'] = state.user!.tel;
                      data['token'] = state.user!.token;
                      data['user_photo'] = state.user!.photoUrl;

                      if (data['title'] == null ||
                          data['description'] == null ||
                          data['category_id'] == null ||
                          image == null) {
                        setState(() {
                          error = "please fill in all the fields";
                          isLoading = false;
                        });
                      } else {
                        try {
                          var objetRef =
                              await _objetservice.saveObjet(data, true);

                          try {
                            if (image != null) {
                              imageUrl =
                                  await _objetservice.uploadFileToFireStorage(
                                      File(image!.path), image!.name);
                            }
                          } catch (e) {
                            print(e);
                          }

                          if (imageUrl != null) {
                            await objetRef.update({"image": imageUrl});
                          }

                          setState(() {
                            isLoading = false;
                            _titleController.clear();
                            _descController.clear();
                            image = null;
                          });
                          Navigator.of(context).pop();
                        } catch (e) {
                          print(e);
                          setState(() {
                            error = e.toString();
                            isLoading = false;
                          });
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
