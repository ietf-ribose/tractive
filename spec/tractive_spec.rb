# frozen_string_literal: true

RSpec.describe Tractive do
  it "has a version number" do
    expect(Tractive::VERSION).not_to be nil
  end

  it "has working info command" do
    expect(Tractive::Info.new.send(:result_hash)).to eq(db_result_hash)
  end

  it "compose correct issue" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request
    ticket = Tractive::Ticket.find(id: 3)

    expect(Tractive::Migrator.new(options_for_migrator).send(:compose_issue, ticket)).to eq(ticket_compose_hash(ticket))
  end

  it "compose correct issue without assignee" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request
    ticket = Tractive::Ticket.find(id: 98)

    expect(Tractive::Migrator.new(options_for_migrator).send(:compose_issue, ticket)).to eq(ticket_compose_hash(ticket))
  end

  it "compose correct issue with all comments as single post" do
    stub_issues_request
    stub_milestone_map_request
    stub_milestone_request

    ticket = Tractive::Ticket.find(id: 170)

    expect(Tractive::Migrator.new(options_for_migrator(singlepost: true)).send(:compose_issue, ticket)).to eq(ticket_compose_hash_with_singlepost(ticket))
  end

  def db_result_hash
    CONFIG.slice("users", "milestones", "labels")
  end

  def options_for_migrator(options = {})
    {
      opts: options,
      cfg: CONFIG,
      db: @db
    }
  end

  def milestones_hash
    {
      "milestone1" => { name: "milestone1", due: 0, completed: 0, description: nil },
      "milestone2" => { name: "milestone2", due: 0, completed: 0, description: nil },
      "milestone3" => { name: "milestone3", due: 0, completed: 0, description: nil },
      "milestone4" => { name: "milestone4", due: 0, completed: 0, description: nil }
    }
  end

  def ticket_compose_hash_with_singlepost(ticket)
    {
      "170" => {
        "issue" => {
          "title" => "Add additional buildbot slaves to test against both legacy and current",
          "body" => "`component_Datatracker: Testing` `resolution_wontfix` `type_task`   |    by henrik@levkowetz.com\n\n___\n\n___\n_@henrik@levkowetz.com_ _changed milestone from `2.02` to ``_\n\n___\n_@henrik@levkowetz.com_ _changed milestone from `` to `Soonish`_\n\n___\n_@pasi.eronen@nokia.com_ _changed status from `new` to `closed`_\n\n___\n_@pasi.eronen@nokia.com_ _set resolution to `wontfix`_\n\n___\n_@pasi.eronen@nokia.com_ _commented_\n\nWe're not currently using buildbot -- will close the ticket.\n\n___\n_Issue migrated from trac:170 at #{Time.now}_",
          "labels" => ["priority_n/a", "tracstate_closed", "owner:"],
          "closed" => true,
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil,
          "assignee" => ""
        },
        "comments" => []
      }
    }[ticket.id.to_s]
  end

  def ticket_compose_hash(ticket)
    {
      "3" => {
        "comments" => [
          { "body" => "_@henrik@levkowetz.com_ _changed status from `new` to `assigned`_", "created_at" => "2007-05-01T16:30:00Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed owner from `henrik` to `henrik@levkowetz.com`_", "created_at" => "2007-05-01T16:30:00Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `assigned` to `closed`_", "created_at" => "2007-06-19T01:55:24Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => "2007-06-19T01:55:24Z" },
          { "body" => "_@fenner@research.att.com_ _changed status from `closed` to `reopened`_", "created_at" => "2007-06-27T09:46:20Z" },
          { "body" => "_@fenner@research.att.com_ _changed resolution from `fixed` to ``_", "created_at" => "2007-06-27T09:46:20Z" },
          { "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nI noticed a couple of major differences between the cgi and django versions:\n\n - The cgi version displays a preview\n - The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n - The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nIf nothing else, the django version should at least send the same kind of email to keep the workflow the same.", "created_at" => "2007-06-27T09:46:20Z" },
          { "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:3 fenner@research.att.com]:\n> I noticed a couple of major differences between the cgi and django versions:\n> \n>  * The cgi version displays a preview\n\nMissing feature in django version.\n\n>  * The cgi version displays a message that the disclosure has been submitted and it will be reviewed and posted.  The django version sends you directly to your new disclosure, which could allow you to post a link to it before it is reviewed and posted.  (Should the view detail say \"this is under review\" instead of showing the disclousre?)\n\nYes. Bug in django version.\n\n>  * The cgi version sends email to the secretariat (in the same general format as the preview) as a notification of the new submission.\n\nRight. Bug (missing functionality) in django version.\n\n> If nothing else, the django version should at least send the same kind of email to keep the workflow the same.\n\nYes.", "created_at" => "2007-06-27T13:11:42Z" },
          { "body" => "_@michael.lee@neustar.biz_ _commented_\n\n\n___\nI have following differences:\n\n- The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\n- You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\n- There is no Review and Confirm page in django. May be this is intended?\n\nMichael.\n", "created_at" => "2007-06-27T19:04:15Z" },
          { "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> I have following differences:\n> \n> * The cgi version allows you to submit an IPR without specifying Disclosure of Patent Information when you select 'Yes' on V.B. The django version doesn't do this.\n\nI think this should be fixed.\n\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI had a discussion with past chairs and others about permitting both RFCs and\ndrafts in the same disclosure (after having asked you (Michael) about this),\nand got go-ahead on that.\n\nIs this something different, or the same issue?\n\n> * There is no Review and Confirm page in django. May be this is intended?\n\nNo, but possibly sufficiently minor that we will fix it later.\n\n> Michael.\n", "created_at" => "2007-06-27T19:16:48Z" },
          { "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nReplying to [comment:5 michael.lee@neustar.biz]:\n> * You can submit an ipr with mixed type of IETF documentations and other contribution (section IV). There was a discussion about this a while ago and this action was prohibited. We may want to bring this up to people like Russ or Scott Bradner if we want to change this rule. If changed, then we will need to test this with secreatariat's interface to make sure the notification messages are going out to proper group of people.\n\nI checked ipr_admin_detail.cgi, command=do_post_it - it uses both ipr_ids and ipr_rfcs and looks up the relevant people for each I-D and RFC individually and adds them all together, so it looks like it already supports it.", "created_at" => "2007-06-27T20:39:29Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed status from `reopened` to `closed`_", "created_at" => "2007-06-28T19:12:15Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed resolution from `` to `fixed`_", "created_at" => "2007-06-28T19:12:15Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed component from `` to `admin/`_", "created_at" => "2007-06-28T19:12:15Z" },
          { "body" => "_removed milestone (was `IPRTool`)_", "created_at" => "2007-06-29T15:30:58Z" },
          { "body" => "_commented_\n\n\n___\nMilestone IPRTool deleted", "created_at" => "2007-06-29T15:30:58Z" }
        ],
        "issue" => {
          "assignee" => "henrik@levkowetz.com",
          "body" => "`component_admin/` `resolution_fixed` `type_task`   |    by henrik@levkowetz.com\n\n___\n\n\n\n\n___\n_Issue migrated from trac:3 at #{Time.now}_",
          "labels" => ["priority_n/a", "tracstate_closed", "owner:henrik@levkowetz.com"],
          "milestone" => nil,
          "title" => "ipr.cgi",
          "closed" => true,
          "created_at" => format_time(ticket[:time])
        }
      }, "98" => {
        "comments" =>[
          { "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\nP.S. using NULL as the \"no RFC\" flag value may not be compatible with existing perl scripts that modify the internet_drafts table.", "created_at" => "2007-06-19T01:47:35Z" },
          { "body" => "_@henrik@levkowetz.com_ _commented_\n\n\n___\nI came across the duplicate draft-for-RFC items last November, and collected a\nlittle bit of information about the situation then:\n```\nSubject: Discrepancies in all_id.txt\nDate: Sat, 18 Nov 2006 10:02:00 +0100\nFrom: Henrik Levkowetz <henrik@levkowetz.com>\nTo: IETF TechSupport via RT <ietf-action@ietf.org>\n\nHi,\n\n\nI just found some discrepancies in all_id.txt, and thus probably in\nthe I-D database from which (I assume) it is generated.\n\nFor 3 RFCs, it lists multiple drafts as being the origin of the RFC,\nwhich seems unlikely.  The following lines all occur in all_id.txt:\n\n  draft-gwinn-paging-protocol-v3-00.txt\t1995-07-03\tRFC\t1861\n  draft-ietf-catnip-common-arch-00.txt\t1994-03-21\tRFC\t1707\n  draft-ietf-hubmib-etherif-mib-07.txt\t1998-06-04\tRFC\t2358\n  draft-ietf-hubmib-etherif-mib-06.txt\t1998-08-06\tRFC\t2358\n  draft-mcgovern-ipng-catnip-wpaper-00.txt\t1994-04-18\tRFC\t1707\n  draft-rfced-info-snpp-v3-00.txt\t1995-09-29\tRFC\t1861\n\n\nOr, re-ordering them a bit:\n\n\n  draft-ietf-catnip-common-arch-00.txt\t1994-03-21\tRFC\t1707\n  draft-mcgovern-ipng-catnip-wpaper-00.txt\t1994-04-18\tRFC\t1707\n\n  draft-gwinn-paging-protocol-v3-00.txt\t1995-07-03\tRFC\t1861\n  draft-rfced-info-snpp-v3-00.txt\t1995-09-29\tRFC\t1861\n\n  draft-ietf-hubmib-etherif-mib-07.txt\t1998-06-04\tRFC\t2358\n  draft-ietf-hubmib-etherif-MIB-06.txt\t1998-08-06\tRFC\t2358\n\n\nThere seems to be different reasons why there are duplicate listings\nfor the source of the RFC in these 3 cases, but in all cases I think\nit would be better to not have duplicate entries...\n\nFor RFC 1707, I can find no traces of draft-mcgovern-ipng-catnip-wpaper-00\non the net, but I have a copy of draft-ietf-catnip-common-arch-00, and\nfind that the diffs between that and the RFC are small.  If you have\na copy of draft-mcgovern-ipng-catnip-wpaper-00 in your archives, I\nsuspect that its text will be even closer to the RFC (given the later\ndate indicated for that draft) and if so it would probably be appropriate\nto mark draft-ietf-catnip-common-arch-00 as being replaced by \ndraft-mcgovern-ipng-catnip-wpaper-00.  Otherwise, I'd simply mark\ndraft-mcgovern-ipng-catnip-wpaper-00 as Expired.\n\nFor RFC 1861, I can find no traces of draft-gwinn-paging-protocol-v3-00,\nand would suggest marking that as either expired or replaced by\ndraft-rfced-info-snpp-v3-00 (which has Gwinn listed as author).\n\nFor RFC 2358, the uppercase 'MIB' in the name seems to be a typo. I have\na copy of both draft-ietf-hubmib-etherif-mib-06 and\ndraft-ietf-hubmib-etherif-mib-07.  The -06 version is dated 'May 1998',\nwhile the -07 is dated 'June 1998'.  I would suggest that the listing\nof draft-ietf-hubmib-etherif-MIB-06 as a separate draft is removed, or\nalternatively it could be marked as replaced by\ndraft-ietf-hubmib-etherif-mib-07.\n```\n", "created_at" => "2007-06-19T01:51:27Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed component from `` to `Base templates`_", "created_at" => "2007-07-10T14:44:36Z" },
          { "body" => "_@henrik@levkowetz.com_ _changed milestone from `` to `FixDatabase`_", "created_at" => "2007-07-10T14:44:36Z" },
          { "body" => "_@henrik@levkowetz.com_ _removed owner (was ``)_", "created_at" => "2007-07-10T14:44:36Z" },
          { "body" => "_@fenner@research.att.com_ _commented_\n\n\n___\n1. The hubmib one would be handled by #180.  The updates would be:\n\n```\n-- RFC 1707:\n-- draft-mcgovern-ipng-catnip-wpaper -> replaced by draft-ietf-catnip-common-arch\nupdate internet_drafts set rfc_number=0, status_id=5, replaced_by=870 where id_document_tag=926;\n\n-- RFC 1861\n-- draft-gwinn-paging-protocol-v3 -> replaced by draft-rfced-info-snpp-v3\nupdate internet_drafts set rfc_number=0, status_id=5, replaced_by=1412 where id_document_tag=1322;\n```\n", "created_at" => "2007-08-02T20:09:30Z" },
          { "body" => "_@pasi.eronen@nokia.com_ _changed status from `new` to `closed`_", "created_at" => "2010-03-24T23:35:17Z" },
          { "body" => "_@pasi.eronen@nokia.com_ _set resolution to `fixed`_", "created_at" => "2010-03-24T23:35:17Z" },
          { "body" => "_@pasi.eronen@nokia.com_ _commented_\n\n\n___\nIt looks like all the other fixes except missing RFCs have been done.\nCreated separate ticket #338 about the missing RFCs; closing this one.", "created_at" => "2010-03-24T23:35:17Z" }
        ],
        "issue" => {
          "title" => "Database consistency: duplicate rfc_number, missing rfcs rows",
          "body" => "`component_Datatracker: Base templates` `resolution_fixed` `type_cleanup`   |    by fenner@research.att.com\n\n___\n\n\nI noticed two problems while trying to validate my Related Documents tool:\n\n1. There are duplicate entries for three RFCs in internet_drafts.  This requires some research to resolve, since it's not completely clear which one is the proper value.  I started to add the following to sql_fixup.sql, but stopped because I didn't want to research what was right:\n\n```\n--\n-- There were duplicates for the rfc_number field.\n-- Since an RFC can only come from a single I-D, there are\n-- various places where the code has this assumption.\n-- The cgi stuff would just get an inconsistent result\n-- in this case, but the django stuff will throw an exception.\n-- So we fix up the cases that we know about, and we make\n-- the RFC number field UNIQUE so that the database won't let\n-- it happen again.\n-- In order for this to work, rfc_number has to be NULL to flag\n-- \"no rfc\", not 0.\nUPDATE internet_drafts SET rfc_number=NULL WHERE rfc_number=0;\n\n-- 1707\n\n-- 1861\n\n-- 2358\nUPDATE internet_drafts SET replaced_by=1764, rfc_number=NULL where id_document_tag=824;\n\nALTER TABLE  `internet_drafts` ADD UNIQUE (`rfc_number`);\n```\n\n2. There are RFCs referred to in internet_drafts that are not in the rfcs table.\n\n```\nmysql> select id_document_tag,a.rfc_number\n from internet_drafts a\n left join rfcs on a.rfc_number = rfcs.rfc_number\n where a.rfc_number != 0\n     and rfcs.rfc_number is null;\n+-----------------+------------+\n| id_document_tag | rfc_number |\n+-----------------+------------+\n|            2977 |       2498 |\n|            4611 |       2873 |\n+-----------------+------------+\n2 rows in set (0.10 sec)\n```\n\nThe easy answer here is to add the corresponding rows for RFCs 2498 and 2873 to the `rfcs` database.\n\n___\n_Issue migrated from trac:98 at #{Time.now}_",
          "labels" => ["priority_n/a", "tracstate_closed", "owner:"],
          "closed" => true,
          "created_at" => format_time(ticket[:time]),
          "milestone" => nil
        }
      }
    }[ticket.id.to_s]
  end

  def stub_issues_request
    stub_request(:get, %r{https://api.github.com/repos/test/repo/issues\?*})
      .to_return(status: 200, body: "[]", headers: {})
  end

  def stub_milestone_map_request
    stub_request(:get, %r{https://api.github.com/repos/test/repo/milestones\?*})
      .to_return(status: 200,
                 body: "[{ \"title\": \"milestone4\", \"number\": 4 }, { \"title\": \"milestone3\", \"number\": 3 },{ \"title\": \"milestone2\", \"number\": 2 },{ \"title\": \"milestone1\", \"number\": 1 } ]",
                 headers: {})
  end

  def stub_milestone_request
    stub_request(:post, "https://api.github.com/repos/test/repo/milestones")
      .to_return(status: 200,
                 body: "[]")
  end

  # TODO: Need to remove this when refactoring migrator class
  def format_time(time)
    time = Time.at(time / 1e6, time % 1e6)
    time.strftime("%FT%TZ")
  end
end
