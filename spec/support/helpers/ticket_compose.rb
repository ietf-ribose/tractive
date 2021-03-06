# frozen_string_literal: true

module Helpers
  module TicketCompose
    def ticket_compose_hash_with_singlepost(ticket)
      {
        "170" => {
          "issue" => {
            "title" => "Add additional buildbot slaves to test against both legacy and current",
            "body" => "`resolution_wontfix` `type_task`   |    by henrik@levkowetz.com\n\n___\n\n___\n_@henrik@levkowetz.com_ _changed milestone from `2.02` to ``_\n\n___\n_@henrik@levkowetz.com_ _changed milestone from `` to `Soonish`_\n\n___\n_@pasi.eronen@nokia.com_ _changed status from `new` to `closed`_\n\n___\n_@pasi.eronen@nokia.com_ _set resolution to `wontfix`_\n\n___\n_@pasi.eronen@nokia.com_ _commented_\n\nWe're not currently using buildbot -- will close the ticket.\n\n___\n_Issue migrated from trac:170 at #{Time.now}_",
            "labels" => ["n/a", "closed", "component: Datatracker: Testing"],
            "closed" => true,
            "closed_at" => format_time(ticket.closed_comments.order(:time).last.time),
            "created_at" => format_time(ticket[:time]),
            "milestone" => nil,
            "assignee" => nil
          },
          "comments" => []
        }
      }[ticket.id.to_s]
    end

    def ticket_compose_hash3(ticket)
      changes = ticket.all_changes
      changes = changes.reject do |c|
        %w[cc reporter version].include?(c.field) ||
          (c.field == "comment" && (c.newvalue.nil? || c.newvalue.lstrip.empty?))
      end

      {
        "issue" => {
          "title" => "ipr.cgi",
          "body" => "`resolution_fixed` `type_task`   |    by henrik@levkowetz.com\n\n___\n\n\n\n\n___\n_Issue migrated from trac:3 at #{Time.now}_",
          "labels" => ["n/a", "closed", "component: admin/", "owner:henrik@levkowetz.com"],
          "closed" => true,
          "closed_at" => format_time(ticket.closed_comments.order(:time).last.time),
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil,
          "assignee" => "henrik@levkowetz.com"
        },
        "comments" => [
          { "body" => "_@henrik@levkowetz.com_ _changed status from `new` to `assigned`_", "created_at" => format_time(changes[0][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed owner from `henrik` to `henrik@levkowetz.com`_", "created_at" => format_time(changes[1][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `assigned` to `closed`_", "created_at" => format_time(changes[2][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => format_time(changes[3][:time]) },
          { "body" => "_@fenner@research.att.com_ _changed status from `closed` to `reopened`_", "created_at" => format_time(changes[4][:time]) },
          { "body" => "_@fenner@research.att.com_ _changed resolution from `fixed` to ``_", "created_at" => format_time(changes[5][:time]) },
          {
            "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nI noticed a couple of major differences between the cgi and django versions:\n\n * The cgi version displays a preview\n * The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n * The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nIf nothing else, the django version should at least send the same kind of email to keep the workflow the same.", "created_at" => format_time(changes[6][:time])
          },
          {
            "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:3 fenner@research.att.com]:\n> I noticed a couple of major differences between the cgi and django versions:\n> \n>  * The cgi version displays a preview\n\nMissing feature in django version.\n\n>  * The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n\nYes. Bug in django version.\n\n>  * The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nRight. Bug (missing functionality) in django version.\n\n> If nothing else, the django version should at least send the same kind of email to keep the workflow the same.\n\nYes.", "created_at" => format_time(changes[7][:time])
          },
          {
            "body" => "_@michael.lee@neustar.biz_ _commented_\n\n\n___\nI have following differences:\n\n* The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\n* You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\n* There is no Review and Confirm page in django. May be this is intended?\n\nMichael.\n", "created_at" => format_time(changes[8][:time])
          },
          {
            "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> I have following differences:\n> \n> * The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\nI think this should be fixed.\n\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI had a discussion with past chairs and others about permitting both RFCs and\ndrafts in the same disclosure (after having asked you (Michael) about this),\nand got go-ahead on that.\n\nIs this something different, or the same issue?\n\n> * There is no Review and Confirm page in django. May be this is intended?\n\nNo, but possibly sufficiently minor that we will fix it later.\n\n> Michael.\n", "created_at" => format_time(changes[9][:time])
          },
          {
            "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI checked ipr_admin_detail.cgi, command=do_post_it - it uses both ipr_ids and ipr_rfcs and looks up the relevant people for each I-D and RFC individually and adds them all together, so it looks like it already supports it.", "created_at" => format_time(changes[10][:time])
          },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `reopened` to `closed`_", "created_at" => format_time(changes[11][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => format_time(changes[12][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed component from `` to `admin/`_", "created_at" => format_time(changes[13][:time]) },
          { "body" => "_removed milestone (was `IPRTool`)_", "created_at" => format_time(changes[14][:time]) },
          { "body" => "_commented_\n\n\n___\nMilestone IPRTool deleted", "created_at" => format_time(changes[15][:time]) }
        ]
      }
    end

    def ticket_compose_hash3_without_owner_label(ticket)
      changes = ticket.all_changes
      changes = changes.reject do |c|
        %w[keywords cc reporter version].include?(c.field) ||
          (c.field == "comment" && (c.newvalue.nil? || c.newvalue.lstrip.empty?))
      end

      {
        "issue" => {
          "title" => "ipr.cgi",
          "body" => "`owner:henrik@levkowetz.com` `resolution_fixed` `type_task`   |    by henrik@levkowetz.com\n\n___\n\n\n\n\n___\n_Issue migrated from trac:3 at #{Time.now}_",
          "labels" => ["n/a", "closed", "component: admin/"],
          "closed" => true,
          "closed_at" => format_time(ticket.closed_comments.order(:time).last.time),
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil,
          "assignee" => "henrik@levkowetz.com"
        },
        "comments" => [
          { "body" => "_@henrik@levkowetz.com_ _changed status from `new` to `assigned`_", "created_at" => format_time(changes[0][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed owner from `henrik` to `henrik@levkowetz.com`_", "created_at" => format_time(changes[1][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `assigned` to `closed`_", "created_at" => format_time(changes[2][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => format_time(changes[3][:time]) },
          { "body" => "_@fenner@research.att.com_ _changed status from `closed` to `reopened`_", "created_at" => format_time(changes[4][:time]) },
          { "body" => "_@fenner@research.att.com_ _changed resolution from `fixed` to ``_", "created_at" => format_time(changes[5][:time]) },
          {
            "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nI noticed a couple of major differences between the cgi and django versions:\n\n * The cgi version displays a preview\n * The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n * The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nIf nothing else, the django version should at least send the same kind of email to keep the workflow the same.", "created_at" => format_time(changes[6][:time])
          },
          {
            "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:3 fenner@research.att.com]:\n> I noticed a couple of major differences between the cgi and django versions:\n> \n>  * The cgi version displays a preview\n\nMissing feature in django version.\n\n>  * The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n\nYes. Bug in django version.\n\n>  * The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nRight. Bug (missing functionality) in django version.\n\n> If nothing else, the django version should at least send the same kind of email to keep the workflow the same.\n\nYes.", "created_at" => format_time(changes[7][:time])
          },
          {
            "body" => "_@michael.lee@neustar.biz_ _commented_\n\n\n___\nI have following differences:\n\n* The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\n* You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\n* There is no Review and Confirm page in django. May be this is intended?\n\nMichael.\n", "created_at" => format_time(changes[8][:time])
          },
          {
            "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> I have following differences:\n> \n> * The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\nI think this should be fixed.\n\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI had a discussion with past chairs and others about permitting both RFCs and\ndrafts in the same disclosure (after having asked you (Michael) about this),\nand got go-ahead on that.\n\nIs this something different, or the same issue?\n\n> * There is no Review and Confirm page in django. May be this is intended?\n\nNo, but possibly sufficiently minor that we will fix it later.\n\n> Michael.\n", "created_at" => format_time(changes[9][:time])
          },
          {
            "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI checked ipr_admin_detail.cgi, command=do_post_it - it uses both ipr_ids and ipr_rfcs and looks up the relevant people for each I-D and RFC individually and adds them all together, so it looks like it already supports it.", "created_at" => format_time(changes[10][:time])
          },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `reopened` to `closed`_", "created_at" => format_time(changes[11][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => format_time(changes[12][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed component from `` to `admin/`_", "created_at" => format_time(changes[13][:time]) },
          { "body" => "_removed milestone (was `IPRTool`)_", "created_at" => format_time(changes[14][:time]) },
          { "body" => "_commented_\n\n\n___\nMilestone IPRTool deleted", "created_at" => format_time(changes[15][:time]) }
        ]
      }
    end

    def ticket_compose_hash98(ticket)
      changes = ticket.all_changes
      changes = changes.reject do |c|
        %w[cc reporter version].include?(c.field) ||
          (c.field == "comment" && (c.newvalue.nil? || c.newvalue.lstrip.empty?))
      end

      {
        "comments" => [
          { "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nP.S. using NULL as the \"no RFC\" flag value may not be compatible with existing perl scripts that modify the internet_drafts table.",
            "created_at" => format_time(changes[0][:time]) },
          {
            "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nI came across the duplicate draft-for-RFC items last November, and collected a\nlittle bit of information about the situation then:\n```\nSubject: Discrepancies in all_id.txt\nDate: Sat, 18 Nov 2006 10:02:00 +0100\nFrom: Henrik Levkowetz <henrik@levkowetz.com>\nTo: IETF TechSupport via RT <ietf-action@ietf.org>\n\nHi,\n\n\nI just found some discrepancies in all_id.txt, and thus probably in\nthe I-D database from which (I assume) it is generated.\n\nFor 3 RFCs, it lists multiple drafts as being the origin of the RFC,\nwhich seems unlikely.  The following lines all occur in all_id.txt:\n\n  draft-gwinn-paging-protocol-v3-00.txt\t1995-07-03\tRFC\t1861\n  draft-ietf-catnip-common-arch-00.txt\t1994-03-21\tRFC\t1707\n  draft-ietf-hubmib-etherif-mib-07.txt\t1998-06-04\tRFC\t2358\n  draft-ietf-hubmib-etherif-mib-06.txt\t1998-08-06\tRFC\t2358\n  draft-mcgovern-ipng-catnip-wpaper-00.txt\t1994-04-18\tRFC\t1707\n  draft-rfced-info-snpp-v3-00.txt\t1995-09-29\tRFC\t1861\n\n\nOr, re-ordering them a bit:\n\n\n  draft-ietf-catnip-common-arch-00.txt\t1994-03-21\tRFC\t1707\n  draft-mcgovern-ipng-catnip-wpaper-00.txt\t1994-04-18\tRFC\t1707\n\n  draft-gwinn-paging-protocol-v3-00.txt\t1995-07-03\tRFC\t1861\n  draft-rfced-info-snpp-v3-00.txt\t1995-09-29\tRFC\t1861\n\n  draft-ietf-hubmib-etherif-mib-07.txt\t1998-06-04\tRFC\t2358\n  draft-ietf-hubmib-etherif-MIB-06.txt\t1998-08-06\tRFC\t2358\n\n\nThere seems to be different reasons why there are duplicate listings\nfor the source of the RFC in these 3 cases, but in all cases I think\nit would be better to not have duplicate entries...\n\nFor RFC 1707, I can find no traces of draft-mcgovern-ipng-catnip-wpaper-00\non the net, but I have a copy of draft-ietf-catnip-common-arch-00, and\nfind that the diffs between that and the RFC are small.  If you have\na copy of draft-mcgovern-ipng-catnip-wpaper-00 in your archives, I\nsuspect that its text will be even closer to the RFC (given the later\ndate indicated for that draft) and if so it would probably be appropriate\nto mark draft-ietf-catnip-common-arch-00 as being replaced by \ndraft-mcgovern-ipng-catnip-wpaper-00.  Otherwise, I'd simply mark\ndraft-mcgovern-ipng-catnip-wpaper-00 as Expired.\n\nFor RFC 1861, I can find no traces of draft-gwinn-paging-protocol-v3-00,\nand would suggest marking that as either expired or replaced by\ndraft-rfced-info-snpp-v3-00 (which has Gwinn listed as author).\n\nFor RFC 2358, the uppercase 'MIB' in the name seems to be a typo. I have\na copy of both draft-ietf-hubmib-etherif-mib-06 and\ndraft-ietf-hubmib-etherif-mib-07.  The -06 version is dated 'May 1998',\nwhile the -07 is dated 'June 1998'.  I would suggest that the listing\nof draft-ietf-hubmib-etherif-MIB-06 as a separate draft is removed, or\nalternatively it could be marked as replaced by\ndraft-ietf-hubmib-etherif-mib-07.\n```\n", "created_at" => format_time(changes[1][:time])
          },
          { "body" => "_@henrik@levkowetz.com_ _changed component from `` to `Base templates`_", "created_at" => format_time(changes[2][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed milestone from `` to `FixDatabase`_", "created_at" => format_time(changes[3][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _removed owner (was ``)_", "created_at" => format_time(changes[4][:time]) },
          {
            "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\n1. The hubmib one would be handled by #180.  The updates would be:\n\n```\n-- RFC 1707:\n-- draft-mcgovern-ipng-catnip-wpaper -> replaced by draft-ietf-catnip-common-arch\nupdate internet_drafts set rfc_number=0, status_id=5, replaced_by=870 where id_document_tag=926;\n\n-- RFC 1861\n-- draft-gwinn-paging-protocol-v3 -> replaced by draft-rfced-info-snpp-v3\nupdate internet_drafts set rfc_number=0, status_id=5, replaced_by=1412 where id_document_tag=1322;\n```\n", "created_at" => format_time(changes[5][:time])
          },
          { "body" => "_@pasi.eronen@nokia.com_ _changed status from `new` to `closed`_", "created_at" => format_time(changes[6][:time]) },
          { "body" => "_@pasi.eronen@nokia.com_ _set resolution to `fixed`_", "created_at" => format_time(changes[7][:time]) },
          {
            "body" => "_@pasi.eronen@nokia.com_ _commented_\n\n\n___\nIt looks like all the other fixes except missing RFCs have been done.\nCreated separate ticket #338 about the missing RFCs; closing this one.", "created_at" => format_time(changes[8][:time])
          }
        ],
        "issue" => {
          "title" => "Database consistency: duplicate rfc_number, missing rfcs rows",
          "body" => "`resolution_fixed` `type_cleanup`   |    by fenner@research.att.com\n\n___\n\n\nI noticed two problems while trying to validate my Related Documents tool:\n\n1. There are duplicate entries for three RFCs in internet_drafts.  This requires some research to resolve, since it's not completely clear which one is the proper value.  I started to add the following to sql_fixup.sql, but stopped because I didn't want to research what was right:\n\n```\n--\n-- There were duplicates for the rfc_number field.\n-- Since an RFC can only come from a single I-D, there are\n-- various places where the code has this assumption.\n-- The cgi stuff would just get an inconsistent result\n-- in this case, but the django stuff will throw an exception.\n-- So we fix up the cases that we know about, and we make\n-- the RFC number field UNIQUE so that the database won't let\n-- it happen again.\n-- In order for this to work, rfc_number has to be NULL to flag\n-- \"no rfc\", not 0.\nUPDATE internet_drafts SET rfc_number=NULL WHERE rfc_number=0;\n\n-- 1707\n\n-- 1861\n\n-- 2358\nUPDATE internet_drafts SET replaced_by=1764, rfc_number=NULL where id_document_tag=824;\n\nALTER TABLE  `internet_drafts` ADD UNIQUE (`rfc_number`);\n```\n\n2. There are RFCs referred to in internet_drafts that are not in the rfcs table.\n\n```\nmysql> select id_document_tag,a.rfc_number\n from internet_drafts a\n left join rfcs on a.rfc_number = rfcs.rfc_number\n where a.rfc_number != 0\n     and rfcs.rfc_number is null;\n+-----------------+------------+\n| id_document_tag | rfc_number |\n+-----------------+------------+\n|            2977 |       2498 |\n|            4611 |       2873 |\n+-----------------+------------+\n2 rows in set (0.10 sec)\n```\n\nThe easy answer here is to add the corresponding rows for RFCs 2498 and 2873 to the `rfcs` database.\n\n___\n_Issue migrated from trac:98 at #{Time.now}_",
          "labels" => ["n/a", "closed", "component: Datatracker: Base templates"],
          "closed" => true,
          "closed_at" => format_time(ticket.closed_comments.order(:time).last.time),
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil
        }
      }
    end

    def ticket_compose_hash872(ticket)
      changes = ticket.all_changes
      changes = changes.reject do |c|
        !c.is_a?(Tractive::Attachment) && (%w[cc reporter version].include?(c.field) ||
          (c.field == "comment" && (c.newvalue.nil? || c.newvalue.lstrip.empty?)))
      end

      {
        "issue" => {
          "title" => "Discusses page has documents with only ex-AD DISCUSSes",
          "body" => "`keyword_hard` `keyword_resnick` `keyword_sprint` `type_defect`   |    by presnick@qualcomm.com\n\n___\n\n\nhttps://datatracker.ietf.org/iesg/discusses/ lists documents where the only DISCUSS holder are retired ADs. It should not have those documents listed.\n\n___\n_Issue migrated from trac:872 at #{Time.now}_",
          "labels" => ["medium", "accepted", "component: doc/"],
          "closed" => false,
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil,
          "assignee" => nil
        },
        "comments" => [
          { "body" => "_@vidyut.luther@neustar.biz_ _uploaded file [`settings.py`](http://www.abc.com/test/ticket/389/389b4f6ee5bd60bebd9d0708da23ba8b4134620b/888c15d72e41c9f0f1882f4aea4c2d19f1a044eb.py) (4.9 KiB)_\n\nExisting settings.py in production right now.", "created_at" => format_time(changes[0][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed priority from `minor` to `medium`_", "created_at" => format_time(changes[1][:time]) },
          { "body" => "_@henrik@levkowetz.com_ _changed keywords from `` to `resnick`_", "created_at" => format_time(changes[2][:time]) },
          { "body" => "_@rjsparks@nostrum.com_ _commented_\n\n\n___\nI've taken several runs at improving this since it was reported. I've been lured by the siren to fix the query rather than fix this particular page's output. It turns out that a query for what this page should show that is both correct and efficient is very hard (perhaps not possible). Instead, we should replumb the page so that we have a chance to remove the set of offending documents from the list being displayed after we've run the query. If it's not done before then, I'll take another run at the next sprint. ", "created_at" => format_time(changes[3][:time]) },
          { "body" => "_@rjsparks@nostrum.com_ _changed keywords from `resnick` to `resnick, sprint`_", "created_at" => format_time(changes[4][:time]) },
          { "body" => "_@jmh@joelhalpern.com_ _changed keywords from `resnick, sprint` to `resnick, sprint, hard`_", "created_at" => format_time(changes[5][:time]) },
          { "body" => "_@rjsparks@nostrum.com_ _changed status from `new` to `accepted`_", "created_at" => format_time(changes[6][:time]) }
        ]
      }
    end
  end
end
