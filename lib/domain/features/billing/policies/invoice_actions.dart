/// What may be done to an invoice a discount or subsidy took to zero.
///
/// A paid invoice is locked: no Edit, no Cancel. That lock protects the payment
/// recorded against it. An invoice whose charges were taken to zero by a
/// discount or subsidy is settled the moment it is sent — it shows as Paid —
/// yet no money was ever put against it, so there is nothing to protect. It
/// stays as editable and cancellable as an unpaid invoice. An invoice a family
/// really paid keeps its lock.
///
/// Whether an invoice is one of these is the server's decision
/// (`fullyReduced`); this only adds the one condition the screens need on top:
/// the invoice has been issued. A draft is already editable, and a cancelled
/// one stays as it is.
bool isChangeableZeroInvoice(String? status, bool? fullyReduced) {
  const issued = {'sent', 'overdue', 'paid', 'success', 'completed'};
  return fullyReduced == true &&
      issued.contains((status ?? '').trim().toLowerCase());
}
