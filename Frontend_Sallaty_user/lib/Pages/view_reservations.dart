import 'package:flutter/material.dart';
import 'orderstore.dart';
import 'client_public_profile.dart';  // ✅ page profil public

class ViewReservationsPage extends StatefulWidget {
  final String offerId;
  const ViewReservationsPage({super.key, required this.offerId});

  @override
  State<ViewReservationsPage> createState() => _ViewReservationsPageState();
}

class _ViewReservationsPageState extends State<ViewReservationsPage> {
  final Color primary = const Color(0xFF72A843);
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() { _loading = true; _error = null; });
    try {
      await OrderStore.instance.fetchMerchantReservations(widget.offerId);
    } catch (e) {
      setState(() { _error = 'Failed to load reservations'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _updateStatus(ReservationRecord r, String newStatus) async {
    final ok = await OrderStore.instance.updateReservationStatus(
      reservationId: r.offerId,
      newStatus: newStatus,
    );
    if (ok && mounted) setState(() { r.status = newStatus; });
  }

  @override
  Widget build(BuildContext context) {
    final reservations =
        OrderStore.instance.getReservations(widget.offerId);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reservations',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primary),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadReservations,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : reservations.isEmpty
                  ? Center(
                      child: Text('No reservations yet',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Colors.grey[500])),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReservations,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: reservations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReservationCard(
                          record: reservations[i],
                          onConfirm: () =>
                              _updateStatus(reservations[i], 'confirmed'),
                          onCancel: () =>
                              _updateStatus(reservations[i], 'canceled'),
                        ),
                      ),
                    ),
    );
  }
}

// ── Carte réservation ─────────────────────────────────────────────
class _ReservationCard extends StatelessWidget {
  final ReservationRecord record;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ReservationCard({
    required this.record,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending   = record.status == 'pending';
    final isConfirmed = record.status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [

          // ✅ Avatar cliquable → profil public du client
          GestureDetector(
            onTap: () {
              if (record.clientId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientPublicProfilePage(
                      clientId: record.clientId,
                    ),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD0E2C0),
              backgroundImage: record.profilePhoto.isNotEmpty
                  ? NetworkImage(record.profilePhoto)
                  : null,
              child: record.profilePhoto.isEmpty
                  ? Text(
                      record.clientName.isNotEmpty
                          ? record.clientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF5F8C38),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Nom + Prix
          Expanded(
            child: GestureDetector(
              // ✅ tap sur le nom aussi → profil public
              onTap: () {
                if (record.clientId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientPublicProfilePage(
                        clientId: record.clientId,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.clientName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (record.price.isNotEmpty)
                    Text(
                      record.price,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF5A5B59),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Badge ou boutons
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? const Color(0xFFA1C582)
                    : const Color(0xFFFFBEBE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isConfirmed ? 'Confirmed' : 'Canceled',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isConfirmed
                      ? Colors.white
                      : const Color(0xFFFF3B3B),
                ),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1C582),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBEBE)
                          .withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF3B3B))),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}