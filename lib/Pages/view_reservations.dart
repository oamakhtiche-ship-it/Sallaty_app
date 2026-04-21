
// Reçoit l'offerId (= offer.title) et affiche uniquement les réservations
// réelles enregistrées dans OrderStore pour cette offre.
//
import 'package:flutter/material.dart';
import 'orderstore.dart';

class ViewReservationsPage extends StatefulWidget {
  final String offerId; // identifiant de l'offre (on utilise le title)

  const ViewReservationsPage({super.key, required this.offerId});

  @override
  State<ViewReservationsPage> createState() => _ViewReservationsPageState();
}

class _ViewReservationsPageState extends State<ViewReservationsPage> {
  final Color primaryColor = const Color(0xFF72A843);

  List<ReservationRecord> get _reservations =>
      OrderStore.instance.getReservations(widget.offerId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'View reservations',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
      body: _reservations.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  // ── État vide ─────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Color(0xFFB0BEC5)),
          SizedBox(height: 16),
          Text(
            'No Reservations Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A5B59),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "You don't have any customer\nreservations for this offer yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Liste ─────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _reservations.length,
      itemBuilder: (context, index) =>
          _buildCard(_reservations[index], index),
    );
  }

  // ── Card réservation ──────────────────────────────────────────────
  Widget _buildCard(ReservationRecord reservation, int index) {
    final bool isPending  = reservation.status == 'pending';
    final bool isCanceled = reservation.status == 'canceled';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Infos client ────────────────────────────────────────
          Row(
            children: [
              // Avatar initiale
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFD0E2C0),
                child: Text(
                  reservation.clientName.isNotEmpty
                      ? reservation.clientName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF72A843),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.clientName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      reservation.timeAgo,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF717270),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge status
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFEF9C2)
                      : isCanceled
                      ? const Color(0xFFFFECEC)
                      : const Color(0xFFD0E2C0),
                  borderRadius: BorderRadius.circular(340),
                ),
                child: Text(
                  isPending
                      ? 'Pending'
                      : isCanceled
                      ? 'Canceled'
                      : 'Confirmed',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isPending
                        ? const Color(0xFFA65F00)
                        : isCanceled
                        ? const Color(0xFFFF3B3B)
                        : const Color(0xFF5F8C38),
                  ),
                ),
              ),
            ],
          ),

          // ── Boutons Confirm / Reject (pending only) ──────────────
          if (isPending && !isCanceled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                // Confirm
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => reservation.status = 'confirmed');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1C582),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Reject
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => reservation.status = 'canceled');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5C5C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}