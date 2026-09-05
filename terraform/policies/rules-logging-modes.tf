# Logging verbosity (NORMAL vs VERBOSE) -- a POLICY-WIDE setting
# (advanced_options_config.log_level), not per-rule.
#
# CORRECTED after real testing during this project's negative-testing
# phase: the original assumption ("VERBOSE adds full match detail, NORMAL
# strips it") was NOT confirmed. Three separate log entries were compared
# across the switch (a DENY under VERBOSE, an equivalent DENY under
# NORMAL, and a fresh ALLOW entry under NORMAL) -- all three showed
# identical field structure: matchedFieldName, matchedFieldType,
# matchedFieldValue, matchedLength, preconfiguredExprIds, remoteIpInfo,
# tlsJa3Fingerprint, tlsJa4Fingerprint were present in every entry
# regardless of log_level.
#
# No field-level difference was observed in this policy's logged output
# between the two settings. The actual difference (if any) may be in log
# VOLUME/sampling rather than per-entry richness, which this test did not
# isolate -- that would need a much higher-traffic comparison to observe,
# not something a handful of manual curl requests can distinguish. Filing
# this as a confirmed correction rather than continuing to assert an
# unverified claim.
locals {
  demo_log_level = "NORMAL" # kept at NORMAL going forward -- VERBOSE
                             # showed no additional benefit in real testing
}
