import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_t/auth.dart';
import 'package:instagram_t/colors.dart';
import 'package:instagram_t/providers/profile_provider.dart';
import 'package:instagram_t/providers/user_profile_provider.dart';
import 'package:instagram_t/resources/firestore_methods.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class UserProfile extends StatefulWidget {
  final User current_user;
  final Map<String, dynamic>? user_follow;
  UserProfile({
    super.key,
    required this.current_user,
    required this.user_follow,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Future<void> _refreshPage() async {
    setState(() {});
  }

  bool _isFollowing = false;
  late Future<Map<String, dynamic>> _userDataFuture;
  late Future<List<Map<String, dynamic>>> _postsFuture;
  bool _isListView = false;
  Map<String, dynamic>? _userData;
  TextStyle myTextStyle = TextStyle(
    fontSize: 15, // Set font size
    fontWeight: FontWeight.bold, // Set font weight
  );
  @override
  void initState() {
    super.initState();
    _userDataFuture = Provider.of<UserProfileProvider>(context, listen: false)
        .getUserData(widget.user_follow!['id'], context);
    _postsFuture = Provider.of<UserProfileProvider>(context, listen: false)
        .getPostsForUsername(widget.user_follow!['id']);
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final isFollowing = await FirestoreMethods().isFollowing(
      Auth.getCurrentUser().uid,
      widget.user_follow!['id'],
    );

    setState(() {
      _isFollowing = isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = _isListView ? 1 : 3;
    double aspectRatio = 1.0;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            context.read<UserProfileProvider>().getUsername().toLowerCase(),
          ),
        ),
        body: FutureBuilder(
            future: Future.wait([_userDataFuture, _postsFuture]),
            builder:
                (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final userData = widget.user_follow;
                final posts = snapshot.data![1] as List<Map<String, dynamic>>;
                return Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              child: ClipOval(
                                  child: SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.network(
                                  cacheHeight: 100,
                                  cacheWidth: 100,
                                  context
                                      .read<UserProfileProvider>()
                                      .getProfilePicture()
                                      .toString(),
                                  fit: BoxFit.cover,
                                ),
                              )),
                              radius: 50,
                            ),
                          ],
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColorGrey),
                              '@' +
                                  context
                                      .read<UserProfileProvider>()
                                      .getUsername()
                                      .toLowerCase()),
                        ),
                      ],
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                          style: TextStyle(fontSize: 15),
                          context
                              .read<UserProfileProvider>()
                              .getDescription()
                              .toLowerCase()),
                    ]),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                  _isFollowing
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                ),
                              ),
                              onPressed: () {
                                if (_isFollowing) {
                                  _unfollowUser(Auth.getCurrentUser().uid,
                                      widget.user_follow!['id']);
                                } else {
                                  _followUser(Auth.getCurrentUser().uid,
                                      widget.user_follow!['id']);
                                }
                              },
                              child: Text(
                                _isFollowing ? 'Unfollow' : 'Follow',
                                style: TextStyle(color: AppColors.onPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [

                              Text(style: myTextStyle, posts.length.toString()),
                              Text(
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textColorGrey),
                                  "posts")
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                  style: myTextStyle,
                                  context
                                      .read<UserProfileProvider>()
                                      .getFollowersCount()
                                      .toString()),
                              Text(
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textColorGrey),
                                  "followers")
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                  style: myTextStyle,
                                  context
                                      .read<UserProfileProvider>()
                                      .getFollowingCount()
                                      .toString()),
                              Text(
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textColorGrey),
                                  "following")
                            ],
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isListView = false;
                            });
                          },
                          child: Container(
                            height: 30,
                            width: 30,
                            child: Icon(
                              Icons.grid_3x3,
                              color: _isListView
                                  ? AppColors.outlinedIcons
                                  : Colors.black,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isListView = true;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            child: Icon(
                              Icons.list,
                              color: _isListView
                                  ? Colors.black
                                  : AppColors.outlinedIcons,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          child: SingleChildScrollView(
                            child: SizedBox(
                                height: 320,
                                width: 350,
                                child: LiquidPullToRefresh(
                                    color: AppColors.primary,
                                    onRefresh: _refreshPage,
                                    child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 2.0,
                                        mainAxisSpacing: 2.0,
                                        childAspectRatio: aspectRatio,
                                      ),
                                      itemCount: posts.length,
                                      itemBuilder: (context, index) {
                                        final post = posts[index];
                                        return Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5)),
                                              border: Border.all(
                                                  color: AppColors.background,
                                                  width: 2.0),
                                            ),
                                            child: ClipRRect(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(5)),
                                                child: CachedNetworkImage(
                                                    imageUrl: post['imageUrl'],
                                                    memCacheHeight: 1014,
                                                    memCacheWidth: 1014,
                                                    fit: BoxFit.cover,
                                                    progressIndicatorBuilder:
                                                        (context, url,
                                                                downloadProgress) =>
                                                            Shimmer(
                                                              direction:
                                                                  ShimmerDirection
                                                                      .fromLeftToRight(), //Default value: Duration(seconds: 0)
                                                              child: Container(
                                                                width: 360,
                                                                height: 350,
                                                                color: Colors
                                                                    .grey[300],
                                                              ),
                                                            ))),
                                          ),
                                        );
                                      },
                                    ))),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              }
            }));
  }

  void _unfollowUser(String current_user_id, other_user_id) async {
    await FirestoreMethods()
        .decrementFollowersCount(other_user_id, current_user_id);
    await FirestoreMethods()
        .decrementFollowingCount(other_user_id, current_user_id);
    setState(() {
      _isFollowing = false;
    });
    if (_userData != null && _userData!['followers_count'] != null) {
      Provider.of<UserProfileProvider>(context, listen: false)
          .updateFollowersCount(
              other_user_id, _userData!['followers_count'] - 1);
    }
  }

  void _followUser(String current_user_id, other_user_id) async {
    await FirestoreMethods()
        .incrementFollowersCount(other_user_id, current_user_id);
    await FirestoreMethods()
        .incrementFollowingCount(other_user_id, current_user_id);
    setState(() {
      _isFollowing = true;
    });
    if (_userData != null && _userData!['followers_count'] != null) {
      Provider.of<UserProfileProvider>(context, listen: false)
          .updateFollowersCount(
              other_user_id, _userData!['followers_count'] + 1);
    }
  }
}
