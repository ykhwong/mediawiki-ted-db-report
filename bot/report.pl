#!/usr/bin/perl 
#
# report.pl - Report creation tool
#
# Filename: report.pl
# Description: Bot operation for the database report
# Author: Taewoong Yoo
# Maintainer: Taewoong Yoo
# Copyright (c) 2015-2018 Taewoong Yoo, all rights reserved.
# Created: Oct 1 2015 01:00 PM Korea
# Version: 0
# Module-Requires: Term::ReadKey, MediaWiki::Bot, WWW::Mechanize, Text::Diff
# Last-Updated: 6 Sep 2018 05:39 AM Korea
#           By: Taewoong Yoo
#     Update #: 127
#               [-] CLEAN UP
#               [MOD] 
# URL: https://github.com/ykhwong
# Keywords: tedbot, bot, wiki, wikipedia, kowiki
# Compatibiltiy: Perl 5 (Tested under RHEL and Windows 7/10)
#
########################################################################################################
#
# Commentary:
# Visit http://ko.wikipedia.org/wiki/User:Ykhwong for more support.
#
use strict;
use File::Basename;
use DateTime;
use Term::ReadKey;
use MediaWiki::Bot qw(:constants);
use Text::Diff;
use POSIX;
use Encode qw(decode encode);
use feature qw/switch/; 
no warnings;
use utf8;
if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'dos') {
	eval "use open ':std', ':encoding(cp949)'";
} else {
	eval "use open ':std', ':encoding(utf8)'";
}

package common_vars;
my $VERSION = "TedKoWiki 20180906_r1";
my ($config_file, $log_file, $diff_file) = ('wiki.conf',  'log.txt', 'diff.diff');
my $mechanize_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.17.8 (KHTML, like Gecko) Version/5.0.1 Safari/533.17.8';
my $bot_agent = 'PerlWikiBot/%s (https://metacpan.org/MediaWiki::Bot; User:%s)';
my ($bot_ko, $bot_en, $bot_userid, $bot_passwd, $userid, $userid_oldid, $savedir);
my $CROSS_PATH_LEADING;
my ($manual_bot, $sleep_begintime, $sleep_endtime, $retry_fail, $verbose, $use_diff, $userid_oldid_cnt) = (0) x 7;
my $sleep_interval_seconds = 60;
my (@entry, @work_array);
my $config_file_content=
"# Lines starting with a # are comment lines and are ignored.\n" .
"# They are used to explain the effect of each option.\n" .
"[common]\n" .
"sleep_interval=$sleep_interval_seconds\n\n" .
"[files]\n" .
"savedir=.\n" .
"log_file=$log_file\n" .
"diff_file=$diff_file\n" .
"[agent]\n" .
"mechanize_agent=$mechanize_agent\n" .
"bot_agent=$bot_agent\n\n";

package custom_vars;
my $not_changed_msg = "[NOT CHANGED] %s (skipped)\n";
my $not_found_msg = "[NOT_FOUND] %s\n";
my $nothing_to_do_msg = "Nothing to do\n";
my $get_items_from_msg = "Getting items from %s...\n";
my $horizontal_line = "=" x 80;

package util;

sub _exit {
	my $retcode = shift;
	if ($bot_ko) {
		$bot_ko->logout();
	}
	exit 1 unless ($retcode =~ /^\d+$/);
	exit $retcode;
}
sub _load_conf {
	my ($data, $group);
	unless ( -f $config_file ) {
		util::_save_to_file($config_file_content, $config_file);
	}
	if ( ! -f $config_file ) {
		printf("Could not create: %s\n", $config_file);
		_exit(1);
	}
	$data = _slurp($config_file);
	foreach my $ls (split /\n/, $data) {
		if ($ls =~ /^\s*#/) { next; }
		if ($ls =~ /^\s*\[\s*(\S+)\s*\]/) {
			$group=$1;
			next;
		}
		if ($ls =~ /=\s*'.+'\s*$/) {
			$ls =~ s/='//;
			$ls =~ s/'\s*$//;
		}
		given ($group) {
			when (/^common$/) {
					if ($ls =~ /^\s*sleep_interval\s*=\s*(\d+)/i) {
							$sleep_interval_seconds=$1;
					}
			}
			when (/^files$/) {
					if ($ls =~ /^\s*savedir\s*=\s*(.+)/i) { $savedir=$1; next; }
					if ($ls =~ /^\s*log_file\s*=\s*(.+)/i) { $log_file=$1; next; }
					if ($ls =~ /^\s*diff_file\s*=\s*(.+)/i) { $diff_file=$1; next; }
			}
			when (/^agent$/) {
					if ($ls =~ /^\s*mechanize_agent\s*=\s*(.+)/i) { $mechanize_agent=$1; next; }
					if ($ls =~ /^\s*bot_agent\s*=\s*(.+)/i) { $bot_agent=$1; next; }
			}
		}
	}
	if ($savedir =~ /\S/) {
		if ( ! -d $savedir ) {
			printf("Cannot find a directory: %s\n", $savedir);
			_exit(1);
		} else {
			$savedir =~ s/(\Q$CROSS_PATH_LEADING\E)+$//g;
		}
	}
}

sub _timed_input {
	my $end_time = time + shift;
	my $string = "00";
	do {
		my $key = ::ReadKey(1);
		$string = $key if defined $key;
	} while (time < $end_time);
	return $string;
};

sub _load_argv {
	($0 = "$0 @ARGV") =~ s/(-|--)botpwd=\K\S+/x/i;

	if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'dos') {
			$CROSS_PATH_LEADING='\\';
	} else {
			$CROSS_PATH_LEADING='/';
	}
	_load_conf();
	my ($sleep_cus, $bslen) = (0) x 2;
	foreach my $item (@ARGV) {
			if ($item =~ /^(-|--)(h|help)$/i || $item =~ /^\/\?$/) {
					my $bsname = ::basename($0);
					if ($bsname =~ /\.pl$/) {
							$bsname = 'perl ' . $bsname;
					}
					$bslen = length($bsname);
					printf("\n  %s\n", $VERSION);
					printf("\n" .
					"  USAGE: %s [--verbose] [--diff] [--manual] [--sleep=SECONDS]\n" .
					"         " . " " x $bslen . " [--botid=ID] [--botpwd=PASSWORD] [--userid=USERID]\n\n" .
					"      --help    : Displays this message\n" .
					"      --verbose : Prevents bot from editing articles\n" .
					"      --diff    : Generates the diff to %s\n" .
					"      --manual  : Manual process regardless of sleep time\n" .
					"      --sleep   : Specifies the sleep time per edit (default: %d)\n"
					, $bsname, $diff_file, $sleep_interval_seconds
					);
					_exit(0);
			}
			given ($item) {
				when (/^(-|--)verbose$/i) { $verbose=1; }
				when (/^(-|--)diff$/i) { $use_diff=1; }
				when (/^(-|--)sleep=(\d+)$/i) { $sleep_cus=$2; }
				when (/^(-|--)manual$/i) { $manual_bot=1; }
				when (/^(-|--)botid=(\S+)$/i) { $bot_userid=$2; }
				when (/^(-|--)botpwd=(\S+)$/i) { $bot_passwd=$2; }
				when (/^(-|--)userid=(\S+)$/i) { $userid=$2; }
			}
	}
	printf("** Verbose mode enabled **\n") if ($verbose eq 1);
	printf("** Diff mode enabled **\n") if ($use_diff eq 1);
	if ($manual_bot eq 1) {
		printf("** Manual mode enabled **\n") 
	} else {
		if ($sleep_cus ne 0) {
			$sleep_interval_seconds=$sleep_cus;
		}
		printf("** Sleep interval is set to %d seconds **\n\n%s\n", $sleep_interval_seconds, $VERSION);
	}
}
sub _ret_line_ending {
	if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'dos') {
			return "\r\n";
	} else {
			return "\n";
	}
}
sub _uniq {
	my %seen;
	grep !$seen{$_}++, @_;
}
sub _assert { # works like die subroutine
	my ($msg, $line) = @_;
	printf("%s (Line: %d)\n", $msg, $line);
	_exit(1);
}
sub _nprint {
	my $output = shift;
	printf($output);
	util::_save_to_file($output, $log_file);
}
sub _remove_file {
	my $filename = shift;
	if ($savedir) {
			$filename = $savedir . $CROSS_PATH_LEADING . $filename;
	}
	unless (-f $filename) {
			return 1;
	}
	unlink $filename;
	return 0;
}
sub _save_to_file {
	my ($output, $filename) = @_;
	if ($savedir) {
			$filename = $savedir . $CROSS_PATH_LEADING . $filename;
	}
	open my $fh, ">>", $filename or _assert(sprintf("Cannot save to %s", $filename), __LINE__);
	print $fh $output;
	close $fh;
}
sub _slurp {
	my $filename = shift;
	if ($savedir) {
			$filename = $savedir . $CROSS_PATH_LEADING . $filename;
	}
	open my $in, '<:utf8', $filename or _assert(sprintf("Cannot open %s for slurping", $filename), __LINE__);
	local $/;
	my $contents = <$in>;
	close($in);
	return $contents;
}
sub _remove_trailing_empty_line {
	my $data = shift;
	my $result;
	my $total_cnt=0;
	my $cnt=0;
	foreach my $ls (split /\n/, $data) { $total_cnt++; }
	foreach my $ls (split /\n/, $data) {
		$cnt++;
		if ($cnt eq $total_cnt) {
			if ($ls =~ /\S+/) {
				$result .= $ls . "\n";
			}
		} else {
			$result .= $ls . "\n";
		}
	}
	return $result;
}
sub _userword {
	my ($msg, $entry_ind) = @_;
	my $userword = undef;
	printf($msg);
	if (@entry) {
			if ($entry_ind =~ /NONE/) {
					# does nothing
			} elsif ($entry_ind =~ /STOP/) {
					printf("Stopped.\n");
					util::_exit(1);
			} elsif ($entry_ind =~ /^\d+$/) {
					printf("%s\n", $entry[$entry_ind]);
					return $entry[$entry_ind];
			} else {
					# should not happen
			}
	}
	$userword = <STDIN>;
	$userword =~ s/(\r|\n)//g; # chomp is not working here
	$userword =~ s/^ +//;
	return $userword;
}
sub _sleep {
	my $rep_inp = undef;
	if ($sleep_begintime eq 0) {
		# does nothing
	} else {
		$sleep_endtime = DateTime->now();
		my $elapse = $sleep_endtime - $sleep_begintime;
		my $elapse2 = $elapse->in_units('seconds');
		if ($elapse2 > $sleep_interval_seconds) {
			# does nothing
		} else {
			$rep_inp=_timed_input($sleep_interval_seconds-$elapse2);
		}
	}
	$sleep_begintime = DateTime->now();
	return $rep_inp;
}
sub _edit {
	my ($title, $wikitext_changed, $summary_text) = @_;
	my $rep_inp;
	if ($wikitext_changed =~ /\{\{ *nobots *\}\}|\{\{bots *\| *allow=none\}\}\E|\{\{ *bots *\| *deny=all\}\}|\{\{ *bots *\| *deny=$bot_userid\}\}/) {
		util::_nprint(sprintf("nobots 틀 존재하므로 무시: %s\n", $title));
		return;
	}
	if ($wikitext_changed =~ /\{\{(bots|allow)=(\S+)/) {
		my $allowbot = $1;
		if ($allowbot !~ /^$bot_userid$/) {
			util::_nprint(sprintf("nobots 틀 존재하므로 무시: %s\n", $title));
			return;
		}
	}

	if ($wikitext_changed !~ /\S/) {
		util::_nprint(sprintf("문서를 비우려고 했습니다: %s\n", $title));
		return;
	}
	_proc_user_talk_oldid();
	if ($manual_bot eq 1) {
		printf(sprintf("[TARGET TITLE] %s\n",$title));
		my $yn = _userword("Bot process [Y/N]?", 'NONE');
		if ($yn =~ /y/i) {
			# ok
		} elsif ($yn =~ /n/i) {
			return;
		} else {
			_exit(1);
		}
	} else {
		$rep_inp = _sleep();
	}
	if ($verbose eq 0) {
		$bot_ko->edit({
			page    => $title,
			text    => $wikitext_changed,
			summary => $summary_text,
		});
	}
	return $rep_inp;
}
sub _diff {
	my ($title, $summary, $c1, $c2) = @_;
	my $diff_result;
	if ($use_diff eq 0) { return; }
	$c1 .= "\n";
	$c2 .= "\n";
	$diff_result .= sprintf("\n--- %s\n+++ %s (%s)\n", $title, $title, $summary) .
	::diff \$c1, \$c2, { STYLE => "Unified" };
	if ($diff_result) {
		util::_save_to_file($diff_result, $diff_file);
	}
}
sub _proc_user_talk_oldid {
	my $cur_oldid = 0;
	my @content;
	if (!$userid || $userid_oldid_cnt !~ /0$/) {
			return;
	}
	@content = util::_get_data_from_url('https://ko.m.wikipedia.org/wiki/특수:역사/사용자토론:' . $userid, 0);
	foreach my $ls (@content) {
			if ($ls =~ /\/(\d+)" class="title">/) {
					$cur_oldid = $1;
					last;
			}
	}
	if ($cur_oldid eq 0) {
			printf("사용자 이름이 잘못되었거나 현재 사용자토론으로 접근이 불가능합니다. - %s\n", $userid);
			_exit(1);
	}
	if (!$userid_oldid) {
			$userid_oldid = $cur_oldid;
			return;
	} else {
			if ($userid_oldid ne $cur_oldid) {
					printf("누군가가 사용자토론(%s)에 글을 남겼습니다\n", $userid);
					@content = util::_get_data_from_url('https://ko.wikipedia.org/w/index.php?title=사용자토론:' . $userid .
					'&diff=' . $cur_oldid . '&oldid=' . $userid_oldid), 0;
					foreach my $ls (@content) {
							if ($ls =~ /<td class="diff-addedline">(<div>.+<\/div>)/) {
									my $addedline = $1;
									$addedline =~ s/^.*<div>//;
									$addedline =~ s/<\/div>//;
									printf("[내용] %s\n\n", $addedline);
									last;
							}
					}
					my $select_yn = util::_userword("[다음/계속: Y, 중단:N] ", 'STOP');
					if ($select_yn =~ /^y$/i) {
							$userid_oldid = $cur_oldid;
					} else {
							_exit(0);
					}
			}
	}
}

package base;
sub _login {
	unless ($bot_userid =~ /\S/) {
			printf("봇 사용자 이름을 입력하십시오.\n");
			$bot_userid = util::_userword("[BOT_USER ID] ", 'NONE');
	}
	if ($bot_userid) {
			if ($bot_userid !~ /(bot|봇)/i) {
					printf("봇 사용자 이름에는 다음의 문자열이 포함되어야 합니다: <봇> 또는 <bot>\n");
					util::_exit(1);
			}
			unless ($bot_passwd =~ /\S/) {
					::ReadMode('noecho');
					$bot_passwd = util::_userword("[PASSWORD] ", 'NONE');
					::ReadMode(0);
			}
			unless ($bot_passwd =~ /\S/) {
					printf("암호를 인식할 수 없습니다.\n");
					util::_exit(1);
			}
			$bot_ko = MediaWiki::Bot->new({
					assert      => 'user',
					protocol    => 'https',
					host        => 'ko.wikipedia.org',
					agent       => sprintf($bot_agent,      MediaWiki::Bot->VERSION, $bot_userid ),
			}) or util::_assert("\nCould not get info (ko)", __LINE__);
			$bot_ko->login({
					username => $bot_userid,
					password => $bot_passwd,
			}) or util::_assert("\nCould not login (ko)", __LINE__);
			#undef $bot_passwd;
			$bot_en = MediaWiki::Bot->new({
					assert      => 'user',
					protocol    => 'https',
					host        => 'en.wikipedia.org',
					agent       => sprintf($bot_agent, MediaWiki::Bot->VERSION, $bot_userid ),
			}) or util::_assert("\nCould not get info (en)", __LINE__);
			printf("\n로그인 성공.\n\n");
			unless ($userid =~ /\S/) {
					printf(
					"봇이 아닌 일반 사용자 이름을 입력하십시오.\n" .
					"해당 사용자 토론이 변경되면 봇은 자동 일시 중단됩니다. (선택 사항)\n"
					);
					$userid = util::_userword("[USER ID] ", 'NONE');
			}
			util::_proc_user_talk_oldid();
	} else {
			util::_exit(1);
	}
	printf("\n\n");
}

util::_load_argv();
base::_login();
$sleep_interval_seconds--;
if ($verbose eq 1) {
	printf("Verbose 모드가 활성화되었으므로 봇의 편집은 비활성화됩니다.\n");
}
while (1) {
	_main();
}

sub _main {
	my %dirs;
	my $cnt=0;
	my $listing;
	opendir(my $dh, "../") || die "Can't open ../: $!";
	while (readdir $dh) {
		my $item = $_;
		next if ($item =~ /^\.|^bot$|^misc$/i);
		next if (! -d "../" . $item);
		$cnt++;
		$dirs{$cnt} = $_;
	    }
	closedir $dh;

	$listing =
	"%s\n" .
	"[Bot Actions]\n";

	foreach my $key (sort {$a <=> $b} keys %dirs) {
		my $val = $dirs{$key};
		$listing .= "$key) $val\n";
	}

	$listing .= "%s\n";
	printf($listing, $horizontal_line, $horizontal_line);
	my $userword = util::_userword("[Enter] ", 0);
	given ($userword) {
		when (/^(\d+)$/) {
			my $action = $dirs{$1};
			if ($action) {
				my $pl = "../${action}/${action}.pl";
				if ( -f $pl ) {
					my $prop_data = util::_slurp("../${action}/action.properties");
					my $title;
					if ($prop_data) {
						if ($prop_data =~ /title=(.+)/) {
							$title=$1;
						}
					}
					my $try = `perl $pl`;
					if ($try) {
						my $wikitext = $bot_ko->get_text($title);
						my $wikitext_changed = ::decode("utf8", $try);
						my ($comp1, $comp2) = ($wikitext, $wikitext_changed);
						$comp1 =~ s/\s+//mg;
						$comp2 =~ s/\s+//mg;
						if ($comp1 eq $comp2) {
					                util::_nprint(sprintf($not_changed_msg, $title));
					                next;
						}
						if ($title) {
							util::_diff($title, 'DB 보고서 업데이트', $wikitext, $wikitext_changed);
							util::_edit($title, $wikitext_changed, "봇: DB 보고서 업데이트");
						}
					}
				}
			}
		}
		when (/^\Q!\E(.*)$/) { system($1); }
		default { print "\n";  }
	}
}

__END__

Copyright 2015-2018 TedKoWiki
This script file was created by User:Ykhwong from ko.wikipedia.org
Tested with Perl 5 version 20 subversion 3 on MS-Windows / Linux

LICENSE
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY.
You may redistribute it and/or modify source code, but you MUST
provide the source code you have made.

