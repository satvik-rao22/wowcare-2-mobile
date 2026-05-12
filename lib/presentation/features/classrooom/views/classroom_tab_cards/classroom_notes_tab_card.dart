import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
// Backend/bloc imports disabled for UI-only mode
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
// import 'package:wowcare/core/services/injection_container.dart';
// import 'package:wowcare/core/util/TimeZoneConfiguration.dart';
// import 'package:wowcare/core/util/core_utils.dart';
// import 'package:wowcare/core/util/typedefs.dart';
// import 'package:wowcare/features/...';
// import 'package:intl/intl.dart' as intl;
// UI-only lightweight models and typedefs
typedef DataMap = Map<String, dynamic>;

class FirestoreUser {
  final String id;
  final UserProfile profile;
  const FirestoreUser({required this.id, required this.profile});
}

class UserProfile {
  final String name;
  final String photoURL;
  final String email;
  const UserProfile({required this.name, this.photoURL = '', this.email = ''});
}

class ClassroomMessage {
  final String id;
  final String text;
  final String senderId;
  final int timestamp;
  final bool isDeleted;
  const ClassroomMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.isDeleted = false,
  });
}

class ClassroomNotesTabCard extends StatefulWidget {
  const ClassroomNotesTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;
  static const routeName = '/classroom-notes-screen';

  @override
  State<ClassroomNotesTabCard> createState() => _ClassroomNotesTabCardState();
}

class _ClassroomNotesTabCardState extends State<ClassroomNotesTabCard> {
  final TextEditingController _searchController = TextEditingController();
  List<FirestoreUser> _users = [];
  List<FirestoreUser> filteredUsers = [];
  List<ClassroomMessage> _messages = [];
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeDummyData() {
    _users = const [
      FirestoreUser(
        id: 'staff_1',
        profile: UserProfile(name: 'Natasha White'),
      ),
      FirestoreUser(
        id: 'staff_2',
        profile: UserProfile(name: 'Eddie Barnes'),
      ),
      FirestoreUser(
        id: 'staff_3',
        profile: UserProfile(name: 'Alex Green'),
      ),
    ];
    final now = DateTime.now().millisecondsSinceEpoch;
    _messages = [
      ClassroomMessage(
        id: '1',
        text:
            "Erica’s Bag is in the office,  Next teacher please take it and give it to the parents",
        senderId: 'staff_1',
        timestamp: now - 600000,
      ),
      ClassroomMessage(
        id: '2',
        text:
            'Children are sleeping now, Please feed them once they wake up',
        senderId: 'staff_2',
        timestamp: now - 300000,
      ),
      ClassroomMessage(
        id: '3',
        text:
            'Children are sleeping now, Please feed them once they wake up',
        senderId: 'staff_2',
        timestamp: now - 120000,
      ),
    ];
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSendMessage(String content) {
    if (content.isEmpty) return;
    final msg = ClassroomMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: content,
      senderId: 'staff_1',
          timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _messages.add(msg);
    });
  }

  String getSenderNameCode(String name) {
    List<String> parts = name.split(' ');
    String firstLetter =
        parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    String secondLetter = '';
    if (parts.length >= 2) {
      secondLetter = parts[1].isNotEmpty ? parts[1][0] : '';
    }
    return '$firstLetter$secondLetter';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Flexible(
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    shape: const Border(
                      left: BorderSide(color: AppColors.themeColor),
                      top: BorderSide(color: AppColors.themeColor),
                      right: BorderSide(color: AppColors.themeColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: SearchBar(
                                    controller: _searchController,
                                    constraints: const BoxConstraints(
                                      maxHeight: 32,
                                      minHeight: 32,
                                    ),
                                    backgroundColor:
                                        const WidgetStatePropertyAll<Color>(
                                      Colors.white,
                                    ),
                                    surfaceTintColor:
                                        const WidgetStatePropertyAll<Color>(
                                      Colors.white,
                                    ),
                                    hintText: 'Search Messages',
                                    hintStyle: WidgetStatePropertyAll(
                                      TextStyle(
                                        fontFamily: 'Manrope',
                                        color:
                                            const Color.fromRGBO(87, 51, 83, 1)
                                                .withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                    elevation: const WidgetStatePropertyAll(0),
                                    side: const WidgetStatePropertyAll(
                                      BorderSide(
                                        width: 1,
                                        color:
                                            Color.fromARGB(255, 188, 173, 186),
                                      ),
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          Row(
                            children: _users
                                .map((user) => Tooltip(
                                      message: user.profile.name,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                            89, 120, 247, 1),
                                        width: 1,
                                      ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                          alignment: Alignment.center,
                                      children: [
                                            DocumentImageWidget(
                                              fileUuid: user.profile.photoURL,
                                              name: user.profile.name,
                                              size: 40,
                                            ),
                                          Positioned(
                                            top: 3,
                                            right: 3,
                                            child: Container(
                                                width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                                children: [
                              Checkbox(
                                value: _showUnreadOnly,
                                onChanged: (v) => setState(() {
                                  _showUnreadOnly = v ?? false;
                                }),
                              ),
                              const Text(
                                'Show Unread Only',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  color: AppColors.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                              height:
                                  10.0), // Spacing before messages or loading
                            Expanded(
                            child: ListView.builder(
                              controller: widget.scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final m = _messages[index];
                                final sender = _users
                                    .firstWhere((u) => u.id == m.senderId);
                                final time = TimeOfDay.fromDateTime(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      m.timestamp),
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                  children: [
                                      Row(
                                        children: [
                                          DocumentImageWidget(
                                            fileUuid: sender.profile.photoURL,
                                            name: sender.profile.name,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(sender.profile.name,
                                              style: const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  color: Color(0xff573353),
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              220, 230, 255, 1),
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                child: Text(
                                          m.text,
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            color:
                                                Color.fromRGBO(87, 51, 83, 1),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                                      const SizedBox(height: 6),
                                      Text(
                                        time.format(context),
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          color:
                                              Color.fromRGBO(65, 65, 78, 0.5),
                                          fontSize: 12,
                                        ),
                          ),
                        ],
                      ),
                                );
                              },
                    ),
                  ),
                          MessageInputField(onSendMessage: _handleSendMessage),
              ],
            ),
          ),
        ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class MessageInputField extends StatefulWidget {
  const MessageInputField({
    super.key, // Corrected Key usage
    required this.onSendMessage,
  });

  final Function(String content) onSendMessage;

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      widget.onSendMessage(content);
      _messageController.clear();
      FocusScope.of(context).unfocus(); // Good UX to dismiss keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 5), // Added vertical margin
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color.fromRGBO(111, 140, 255, 1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLength: 2000,
                  decoration: const InputDecoration(
                      hintText: 'Type your message here ...',
                      hintStyle: TextStyle(
                        fontFamily: 'Manrope',
                        color: Color.fromRGBO(87, 51, 83, 0.6),
                        fontSize: 14,
                      ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10) // Added padding for text field
                  ),
              cursorColor: const Color.fromRGBO(87, 51, 83, 1),
              textInputAction:
                  TextInputAction.send, // Allows sending via keyboard action
              onSubmitted: (_) => _sendMessage(), // Handle keyboard send action
              minLines: 1,
              maxLines: 5, // Allow multi-line messages
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(111, 140, 255, 1),
                  Color.fromRGBO(156, 132, 255, 1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Send',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Removed complex ClassroomMessagesList and bubble widgets for UI-only flow
