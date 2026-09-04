/// How long a message stays on screen at the till.
///
/// Two QA passes independently reported the same thing: the wording made sense but the
/// message was gone before it could be acted on. These are not equivalent messages, so they
/// do not get equivalent time.
///
/// A success is a confirmation of something the cashier just did deliberately — they already
/// know what happened, and the toast is a receipt. Four seconds is plenty, and longer means
/// it is still sitting there over the next customer.
///
/// A refusal or an error is the opposite: it reports something the cashier did NOT expect,
/// it usually names a constraint they have to reason about ("need 12, have 11"), and there
/// is often a queue in front of them while they read it. Eight seconds is roughly the time
/// to read a sentence, look at the shelf, and look back.
const Duration kSuccessToastDuration = Duration(seconds: 4);

/// Errors, refusals and failed lookups. See above for why this is double the success time.
const Duration kErrorToastDuration = Duration(seconds: 8);
