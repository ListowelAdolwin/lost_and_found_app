import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/src/utils/app_colors.dart';
import 'package:lost_and_found/src/widget/objet_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  late Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream;
  bool isLost = true;
  String selectedCategory = "1";
  String currentObject = "CNI";
  @override
  void initState() {
    categoriesStream =
        FirebaseFirestore.instance.collection("categories").snapshots();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Search",
          style: TextStyle(
            color: AppColors.primaryGrayText,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenHeight * .05,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: isLost,
                      onChanged: (value) {
                        print(value);
                        if (isLost != true) {
                          setState(() {
                            isLost = value!;
                          });
                        }
                      },
                    ),
                    const Text(
                      "Lost Object",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isLost,
                      onChanged: (value) {
                        print(value);
                        if (isLost != false) {
                          setState(() {
                            isLost = value!;
                          });
                        }
                      },
                    ),
                    const Text(
                      "Found Object",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            width: screenWidth,
            height: screenHeight * .05,
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: categoriesStream,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }

                      if (snapshot.hasData) {
                        if (snapshot.data!.size == 0) {
                          return Container(); //? shimmer yet
                        } else {
                          List<QueryDocumentSnapshot<Object?>> cats =
                              snapshot.data!.docs;

                          return ListView(
                            scrollDirection: Axis.horizontal,
                            children: cats.map((cat) {
                              return GestureDetector(
                                onTap: () {
                                  selectedCategory = cat['id'];
                                  currentObject = cat['title'];
                                  setState(() {});

                                  print(cat['id']);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Chip(
                                    backgroundColor:
                                        selectedCategory == cat['id']
                                            ? AppColors.primary
                                            : null,
                                    label: Text(
                                      cat['title'],
                                      style: TextStyle(
                                        color: selectedCategory == cat['id']
                                            ? Colors.white
                                            : AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                      }
                      return Container();
                    },
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: isLost
                  ? FirebaseFirestore.instance
                      .collection("lost_objet")
                      .orderBy("createdAt", descending: true)
                      .where("category_id", isEqualTo: selectedCategory)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection("found_objet")
                      .orderBy("createdAt", descending: true)
                      .where("category_id", isEqualTo: selectedCategory)
                      .snapshots(),
              builder: ((BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "${snapshot.error}",
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  var data = snapshot.data!.docs;

                  if (snapshot.data!.size == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: isLost
                            ? Text(
                                "No lost $currentObject yet",
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 18,
                                ),
                              )
                            : Text(
                                "No found $currentObject yet",
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    );
                  } else {
                    return ListView.separated(
                      //controller: scrollController,
                      itemCount: snapshot.data!.size,
                      separatorBuilder: (context, index) {
                        return Container(
                          height: screenHeight * 0.01,
                          decoration:
                              const BoxDecoration(color: AppColors.grayScale),
                        );
                      },
                      itemBuilder: (context, index) {
                        var object = data[index];

                        return ObjetWidget(
                          title: object['title'],
                          description: object['description'],
                          image: object['image'],
                          userId: object['user_id'],
                          userImage: object['user_photo'],
                          username: object['user_name'],
                          createAd: object['createdAt'],
                          usersubname: object['user_subname'],
                          isLost: true,
                        );
                      },
                    );
                  }
                }

                return Container();
              }),
            ),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
