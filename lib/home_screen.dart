import 'package:flutter/material.dart';
import 'room_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<String> locations = ['옥계', '학교 앞', '신평동'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('원룸 알리미'),
      ),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(locations[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RoomDetailsScreen(location: locations[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
