import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

final orpc = OdooClient('https://eservices2.odoo.com');
void main() async {
  await orpc.authenticate('eservices2', 'mohamed010279316@gmail.com', '123456');
  final res = await orpc.callRPC('/web/session/modules', 'call', {});
  print('Installed modules: \n$res');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //TODO change model to model Name Like : crm.lead for CRM Module
  void createContact() async {
    // Create partner
    var id = await orpc.callKw({
      'model': 'crm.lead',
      'method': 'create',
      'args': [
        {
          'name': "Ticket Created",
          'phone': '+10551541515',
          'expected_revenue': '140',
          'email_from': 'User@Email.com',
        },
      ],
      'kwargs': {},
    });
    print('Ticket ID : $id');
  }

  Future<dynamic> fetchContacts() {
    //TODO change model to model Name Like : crm.lead for CRM Module

    return orpc.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'context': {'bin_size': true},
        'domain': [],
        'fields': [
          'id',
          'name',
          'phone',
          'expected_revenue',
          'email_from',
        ],
        'limit': 80,
      },
    });
  }

  Widget buildListItem(Map<String, dynamic> record) {
    // var unique = record['__last_update'] as String;
    // unique = unique.replaceAll(RegExp(r'[^0-9]'), '');
    final avatarUrl =
        '${orpc.baseURL}/web/image?model=res.partner&field=image_128&id=${record["id"]}';
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
      title: Text(record['name']),
      subtitle:
          Text(record['email_from'] is String ? record['email_from'] : ''),
      trailing: Text(record['id'].toString()),
      onTap: () async {
        //Set Ticket to Won Stage
        // await orpc.callKw(
        //   {
        //     'model': 'crm.lead',
        //     'method': 'action_set_won_rainbowman',
        //     'args': [
        //       record['id'], // Ticket ID
        //     ],
        //     'kwargs': {},
        //   },
        // );

        //Stage ID => Starting from 1 to the end Stage ID
        // 1 => New | 2 => Qualified | 4 => won

        await orpc.callKw(
          {
            'model': 'crm.lead',
            'method': 'write',
            'args': [
              record['id'],
              {'stage_id': 4},
            ],
            'kwargs': {},
          },
        );

// Log the updated lead ID
        print('Updated lead ID: ${record['id']}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Modules'),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0.0,
        onPressed: () => createContact(),
        child: const Icon(
          Icons.add,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          fetchContacts();

          return Future.delayed(
            const Duration(milliseconds: 100),
            () {
              setState(() {});
            },
          );
        },
        child: FutureBuilder(
            future: fetchContacts(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final record =
                          snapshot.data[index] as Map<String, dynamic>;
                      return buildListItem(record);
                    });
              } else {
                if (snapshot.hasError) {
                  return const Text('Unable to fetch data');
                }
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}
