import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_payout_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminPayoutsScreen extends StatelessWidget {
  const AdminPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminPayoutController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payout Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      drawer: const AdminDrawer(),
      body: Obx(() {
        if(controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));

        return ListView.builder(
          itemCount: controller.payouts.length,
          itemBuilder: (context, index) {
            final payout = controller.payouts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: Icon(Icons.attach_money, color: AppTheme.primaryColor)),
                title: Text(payout['seller']),
                subtitle: Text("Bank: ${payout['bank']}\nStatus: ${payout['status']}"),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(payout['amount'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    if(payout['status'] == 'Pending')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: ()=> controller.updatePayoutStatus(payout['id'], 'Approved'), 
                          child: const Icon(Icons.check_circle, color: Colors.green)
                        ),
                        const SizedBox(width: 10),
                         InkWell(
                          onTap: ()=> controller.updatePayoutStatus(payout['id'], 'Rejected'), 
                          child: const Icon(Icons.cancel, color: Colors.red)
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
