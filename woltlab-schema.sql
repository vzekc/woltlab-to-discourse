create table gallery3_image_search_index
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.woltlab.gallery.image' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on gallery3_image_search_index (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on gallery3_image_search_index (subject);

create index language
  on gallery3_image_search_index (languageID);

create index user
  on gallery3_image_search_index (userID, time);

create table wbb1_1_board
(
  boardID                     int(10) auto_increment
        primary key,
  parentID                    int(10)                                              default 0           not null,
  title                       varchar(255)                                         default ''          not null,
  description                 mediumtext                                                               null,
  allowDescriptionHtml        tinyint(1)                                           default 0           not null,
  boardType                   tinyint(1)                                           default 0           not null,
  image                       varchar(255)                                         default ''          not null,
  imageNew                    varchar(255)                                         default ''          not null,
  imageShowAsBackground       tinyint(1)                                           default 1           not null,
  imageBackgroundRepeat       enum ('no-repeat', 'repeat-y', 'repeat-x', 'repeat') default 'no-repeat' not null,
  externalURL                 varchar(255)                                         default ''          not null,
  time                        int(10)                                              default 0           not null,
  prefixes                    mediumtext                                                               null,
  prefixRequired              tinyint(1)                                           default 0           not null,
  prefixMode                  tinyint(1)                                           default 0           not null,
  styleID                     int(10)                                              default 0           not null,
  enforceStyle                tinyint(1)                                           default 0           not null,
  daysPrune                   smallint(5)                                          default 0           not null,
  sortField                   varchar(20)                                          default ''          not null,
  sortOrder                   varchar(4)                                           default ''          not null,
  postSortOrder               varchar(4)                                           default ''          not null,
  isClosed                    tinyint(1)                                           default 0           not null,
  countUserPosts              tinyint(1)                                           default 1           not null,
  isInvisible                 tinyint(1)                                           default 0           not null,
  showSubBoards               tinyint(1)                                           default 1           not null,
  clicks                      int(10)                                              default 0           not null,
  threads                     int(10)                                              default 0           not null,
  posts                       int(10)                                              default 0           not null,
  enableRating                tinyint(1)                                           default -1          not null,
  threadsPerPage              smallint(5)                                          default 0           not null,
  postsPerPage                smallint(5)                                          default 0           not null,
  searchable                  tinyint(1)                                           default 1           not null,
  searchableForSimilarThreads tinyint(1)                                           default 1           not null,
  ignorable                   tinyint(1)                                           default 1           not null,
  enableMarkingAsDone         tinyint(1)                                           default 0           not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_closed_category_to_admin
(
  boardID int(10) default 0 not null,
  userID  int(10) default 0 not null,
  primary key (userID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create index boardID
  on wbb1_1_board_closed_category_to_admin (boardID);

create table wbb1_1_board_closed_category_to_user
(
  boardID  int(10)    default 0 not null,
  userID   int(10)    default 0 not null,
  isClosed tinyint(1) default 0 not null,
  primary key (userID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create index boardID
  on wbb1_1_board_closed_category_to_user (boardID);

create table wbb1_1_board_ignored_by_user
(
  boardID int(10) default 0 not null,
  userID  int(10) default 0 not null,
  primary key (userID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create index boardID
  on wbb1_1_board_ignored_by_user (boardID);

create table wbb1_1_board_information
(
  boardID     int(10)                                                          not null
        primary key,
  message     text                                                             not null,
  displayType enum ('info', 'warning', 'error', 'success') default 'info'      not null,
  displayOn   enum ('newThread', 'newReply', 'both')       default 'newThread' not null,
  inherit     tinyint(1)                                   default 0           not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_information_to_user
(
  boardID int(10) not null,
  userID  int(10) not null,
  primary key (boardID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_last_post
(
  boardID    int(10) default 0 not null,
  languageID int(10) default 0 not null,
  threadID   int(10) default 0 not null,
  primary key (boardID, languageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_moderator
(
  boardID                   int(10)    default 0  not null,
  userID                    int(10)    default 0  not null,
  groupID                   int(10)    default 0  not null,
  canDeleteThread           tinyint(1) default -1 not null,
  canReadDeletedThread      tinyint(1) default -1 not null,
  canDeleteThreadCompletely tinyint(1) default -1 not null,
  canCloseThread            tinyint(1) default -1 not null,
  canEnableThread           tinyint(1) default -1 not null,
  canMoveThread             tinyint(1) default -1 not null,
  canCopyThread             tinyint(1) default -1 not null,
  canMergeThread            tinyint(1) default -1 not null,
  canEditPost               tinyint(1) default -1 not null,
  canDeletePost             tinyint(1) default -1 not null,
  canReadDeletedPost        tinyint(1) default -1 not null,
  canDeletePostCompletely   tinyint(1) default -1 not null,
  canClosePost              tinyint(1) default -1 not null,
  canEnablePost             tinyint(1) default -1 not null,
  canMovePost               tinyint(1) default -1 not null,
  canCopyPost               tinyint(1) default -1 not null,
  canMergePost              tinyint(1) default -1 not null,
  canReplyClosedThread      tinyint(1) default -1 not null,
  canPinThread              tinyint(1) default -1 not null,
  canStartAnnouncement      tinyint(1) default -1 not null,
  canMarkAsDoneThread       tinyint(1) default -1 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index groupID
  on wbb1_1_board_moderator (groupID);

create index userID
  on wbb1_1_board_moderator (userID);

create table wbb1_1_board_structure
(
  parentID int(10)     default 0 not null,
  boardID  int(10)     default 0 not null,
  position smallint(5) default 0 not null,
  primary key (parentID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_subscription
(
  userID             int(10)    default 0 not null,
  boardID            int(10)    default 0 not null,
  enableNotification tinyint(1) default 0 not null,
  emails             tinyint(3) default 0 not null,
  primary key (userID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_to_group
(
  boardID                         int(10)    default 0  not null,
  groupID                         int(10)    default 0  not null,
  canViewBoard                    tinyint(1) default -1 not null,
  canEnterBoard                   tinyint(1) default -1 not null,
  canReadThread                   tinyint(1) default -1 not null,
  canReadOwnThread                tinyint(1) default -1 not null,
  canStartThread                  tinyint(1) default -1 not null,
  canReplyThread                  tinyint(1) default -1 not null,
  canReplyOwnThread               tinyint(1) default -1 not null,
  canStartThreadWithoutModeration tinyint(1) default -1 not null,
  canReplyThreadWithoutModeration tinyint(1) default -1 not null,
  canStartPoll                    tinyint(1) default -1 not null,
  canVotePoll                     tinyint(1) default -1 not null,
  canRateThread                   tinyint(1) default -1 not null,
  canUsePrefix                    tinyint(1) default -1 not null,
  canUploadAttachment             tinyint(1) default -1 not null,
  canDownloadAttachment           tinyint(1) default -1 not null,
  canViewAttachmentPreview        tinyint(1) default -1 not null,
  canDeleteOwnPost                tinyint(1) default -1 not null,
  canEditOwnPost                  tinyint(1) default -1 not null,
  canSetTags                      tinyint(1) default -1 not null,
  canMarkAsDoneOwnThread          tinyint(1) default -1 not null,
  primary key (groupID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_to_user
(
  boardID                         int(10)    default 0  not null,
  userID                          int(10)    default 0  not null,
  canViewBoard                    tinyint(1) default -1 not null,
  canEnterBoard                   tinyint(1) default -1 not null,
  canReadThread                   tinyint(1) default -1 not null,
  canReadOwnThread                tinyint(1) default -1 not null,
  canStartThread                  tinyint(1) default -1 not null,
  canReplyThread                  tinyint(1) default -1 not null,
  canReplyOwnThread               tinyint(1) default -1 not null,
  canStartThreadWithoutModeration tinyint(1) default -1 not null,
  canReplyThreadWithoutModeration tinyint(1) default -1 not null,
  canStartPoll                    tinyint(1) default -1 not null,
  canVotePoll                     tinyint(1) default -1 not null,
  canRateThread                   tinyint(1) default -1 not null,
  canUsePrefix                    tinyint(1) default -1 not null,
  canUploadAttachment             tinyint(1) default -1 not null,
  canDownloadAttachment           tinyint(1) default -1 not null,
  canViewAttachmentPreview        tinyint(1) default -1 not null,
  canDeleteOwnPost                tinyint(1) default -1 not null,
  canEditOwnPost                  tinyint(1) default -1 not null,
  canSetTags                      tinyint(1) default -1 not null,
  canMarkAsDoneOwnThread          tinyint(1) default -1 not null,
  primary key (userID, boardID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_board_visit
(
  boardID       int(10) default 0 not null,
  userID        int(10) default 0 not null,
  lastVisitTime int(10) default 0 not null,
  primary key (boardID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wbb1_1_board_visit (userID, lastVisitTime);

create table wbb1_1_feed_poster
(
  fpID             int(10) auto_increment
        primary key,
  name             varchar(255) not null,
  userID           int(10)      not null,
  boardID          int(10)      not null,
  languageID       int(10)      not null,
  threadLimit      int(10)      not null,
  threadType       tinyint(1)   not null,
  threadPrefix     varchar(255) not null,
  threadClosed     tinyint(1)   not null,
  threadDisabled   tinyint(1)   not null,
  threadCountPosts tinyint(1)   not null,
  disabledFp       tinyint(1)   not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_feed_poster_url
(
  urlID       int(10) auto_increment
        primary key,
  fpID        int(10)      not null,
  url         varchar(255) not null,
  type        varchar(10)  not null,
  searchTags  text         not null,
  disabledUrl tinyint(1)   not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_import_mapping
(
  idType varchar(75)      default '' not null,
  oldID  varchar(255)     default '' not null,
  newID  int(11) unsigned default 0  not null,
  constraint idType
    unique (idType, oldID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_import_source
(
  sourceName   varchar(255)                not null,
  packageID    int(11) unsigned default 0  not null,
  classPath    varchar(255)                not null,
  templateName varchar(255)     default '' not null,
  constraint sourceName
    unique (sourceName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_post
(
  postID        int(10) auto_increment
        primary key,
  threadID      int(10)      default 0  not null,
  parentPostID  int(10)      default 0  not null,
  userID        int(10)      default 0  not null,
  username      varchar(255) default '' not null,
  subject       varchar(255) default '' not null,
  message       mediumtext              not null,
  time          int(10)      default 0  not null,
  isDeleted     tinyint(1)   default 0  not null,
  everEnabled   tinyint(1)   default 1  not null,
  isDisabled    tinyint(1)   default 0  not null,
  isClosed      tinyint(1)   default 0  not null,
  editor        varchar(255) default '' not null,
  editorID      int(10)      default 0  not null,
  lastEditTime  int(10)      default 0  not null,
  editCount     mediumint(7) default 0  not null,
  editReason    text                    null,
  deleteTime    int(10)      default 0  not null,
  deletedBy     varchar(255) default '' not null,
  deletedByID   int(10)      default 0  not null,
  deleteReason  text                    null,
  attachments   smallint(5)  default 0  not null,
  pollID        int(10)      default 0  not null,
  enableSmilies tinyint(1)   default 1  not null,
  enableHtml    tinyint(1)   default 0  not null,
  enableBBCodes tinyint(1)   default 1  not null,
  showSignature tinyint(1)   default 1  not null,
  ipAddress     varchar(15)  default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index ipAddress
  on wbb1_1_post (ipAddress);

create index isDeleted
  on wbb1_1_post (isDeleted);

create index isDisabled
  on wbb1_1_post (isDisabled);

create index parentPostID
  on wbb1_1_post (parentPostID);

create index post_time
  on wbb1_1_post (time, postID);

create fulltext index subject
    on wbb1_1_post (subject, message);

create index threadID
  on wbb1_1_post (threadID, userID);

create index threadID_2
  on wbb1_1_post (threadID, isDeleted, isDisabled, time);

create index userID
  on wbb1_1_post (userID);

create table wbb1_1_post_cache
(
  postID       int(10) default 0 not null
        primary key,
  threadID     int(10) default 0 not null,
  messageCache mediumtext        not null
)
  engine = MyISAM
    charset = utf8mb3;

create index threadid
  on wbb1_1_post_cache (threadID);

create table wbb1_1_post_hash
(
  postID      int(10)                not null,
  time        int(10)     default 0  not null,
  messageHash varchar(40) default '' not null
    primary key
)
  engine = MyISAM
    charset = utf8mb3;

create index postID
  on wbb1_1_post_hash (postID);

create table wbb1_1_post_report
(
  reportID   int(10) auto_increment
        primary key,
  postID     int(10) default 0 not null,
  userID     int(10) default 0 not null,
  report     mediumtext        not null,
  reportTime int(10) default 0 not null,
  constraint postID
    unique (postID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_thread
(
  threadID         int(10) auto_increment
        primary key,
  boardID          int(10)      default 0  not null,
  languageID       int(10)      default 0  not null,
  prefix           varchar(255) default '' not null,
  topic            varchar(255) default '' not null,
  firstPostID      int(10)      default 0  not null,
  firstPostPreview text                    null,
  time             int(10)      default 0  not null,
  userID           int(10)      default 0  not null,
  username         varchar(255) default '' not null,
  lastPostTime     int(10)      default 0  not null,
  lastPosterID     int(10)      default 0  not null,
  lastPoster       varchar(255) default '' not null,
  replies          mediumint(7) default 0  not null,
  views            mediumint(7) default 0  not null,
  ratings          smallint(5)  default 0  not null,
  rating           mediumint(7) default 0  not null,
  attachments      smallint(5)  default 0  not null,
  polls            smallint(5)  default 0  not null,
  isAnnouncement   tinyint(1)   default 0  not null,
  isSticky         tinyint(1)   default 0  not null,
  isDisabled       tinyint(1)   default 0  not null,
  everEnabled      tinyint(1)   default 1  not null,
  isClosed         tinyint(1)   default 0  not null,
  isDeleted        tinyint(1)   default 0  not null,
  movedThreadID    int(10)      default 0  not null,
  movedTime        int(10)      default 0  not null,
  deleteTime       int(10)      default 0  not null,
  deletedBy        varchar(255) default '' not null,
  deletedByID      int(10)      default 0  not null,
  deleteReason     text                    null,
  isDone           tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index boardID
  on wbb1_1_thread (boardID, isAnnouncement, isSticky, lastPostTime, isDeleted, isDisabled);

create index firstPostID
  on wbb1_1_thread (firstPostID);

create index isClosed
  on wbb1_1_thread (isClosed);

create index isDeleted
  on wbb1_1_thread (isDeleted);

create index isDisabled
  on wbb1_1_thread (isDisabled);

create index languageID
  on wbb1_1_thread (languageID);

create index lastPostTime
  on wbb1_1_thread (lastPostTime);

create index movedThreadID
  on wbb1_1_thread (movedThreadID);

create index movedTime
  on wbb1_1_thread (movedTime);

create index rating
  on wbb1_1_thread (boardID, rating, ratings);

create index replies
  on wbb1_1_thread (replies, boardID);

create index thread_time
  on wbb1_1_thread (time, threadID);

create fulltext index topic
    on wbb1_1_thread (topic);

create index userID
  on wbb1_1_thread (userID);

create index userID_2
  on wbb1_1_thread (userID, username, threadID);

create index views
  on wbb1_1_thread (views);

create index views_2
  on wbb1_1_thread (views, boardID);

create table wbb1_1_thread_announcement
(
  boardID  int(10) default 0 not null,
  threadID int(10) default 0 not null,
  primary key (boardID, threadID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_thread_rating
(
  threadID  int(10)     default 0  not null,
  rating    int(10)     default 0  not null,
  userID    int(10)     default 0  not null,
  ipAddress varchar(15) default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index threadID
  on wbb1_1_thread_rating (threadID, userID);

create index threadID_2
  on wbb1_1_thread_rating (threadID, ipAddress);

create table wbb1_1_thread_similar
(
  threadID        int(10) default 0 not null,
  similarThreadID int(10) default 0 not null,
  constraint threadID
    unique (threadID, similarThreadID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_thread_subscription
(
  userID             int(10)    default 0 not null,
  threadID           int(10)    default 0 not null,
  enableNotification tinyint(1) default 0 not null,
  emails             tinyint(3) default 0 not null,
  primary key (userID, threadID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wbb1_1_thread_visit
(
  threadID      int(10) default 0 not null,
  userID        int(10) default 0 not null,
  lastVisitTime int(10) default 0 not null,
  primary key (threadID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wbb1_1_thread_visit (userID, lastVisitTime);

create table wbb1_1_user
(
  userID                     int(10) auto_increment
        primary key,
  boardLastVisitTime         int(10)      default 0 not null,
  boardLastActivityTime      int(10)      default 0 not null,
  boardLastMarkAllAsReadTime int(10)      default 0 not null,
  posts                      mediumint(7) default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index posts
  on wbb1_1_user (posts);

create table wbb1_1_user_last_post
(
  userID int(10) default 0 not null,
  postID int(10) default 0 not null,
  time   int(10) default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index postID
  on wbb1_1_user_last_post (postID);

create index userID
  on wbb1_1_user_last_post (userID);

create table wbb3_post_search_index
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.woltlab.wbb.post' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on wbb3_post_search_index (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on wbb3_post_search_index (subject);

create index language
  on wbb3_post_search_index (languageID);

create index user
  on wbb3_post_search_index (userID, time);

create table wbb3_thread_form
(
  formID int(10) auto_increment
        primary key,
  title  varchar(255) default '' not null
)
  collate = utf8mb4_unicode_ci;

create table wbb3_thread_form_option
(
  optionID          int(10) auto_increment
        primary key,
  optionTitle       varchar(255) default '' not null,
  optionDescription text                    null,
  optionType        varchar(255) default '' not null,
  defaultValue      mediumtext              null,
  validationPattern text                    null,
  selectOptions     mediumtext              null,
  required          tinyint(1)   default 0  not null,
  showOrder         int(10)      default 0  not null,
  isDisabled        tinyint(1)   default 0  not null,
  tmpHash           varchar(40)             null,
  timeCreated       int(10)                 null,
  formID            int                     null,
  constraint e8415e64bce8ccce9e93464983476d6b_fk
    foreign key (formID) references wbb3_thread_form (formID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf1_acp_menu_item
(
  menuItemID     int unsigned auto_increment
        primary key,
  packageID      int unsigned default 0  not null,
  menuItem       varchar(255) default '' not null,
  parentMenuItem varchar(255) default '' not null,
  menuItemLink   varchar(255) default '' not null,
  menuItemIcon   varchar(255) default '' not null,
  showOrder      int unsigned default 0  not null,
  permissions    text                    null,
  options        text                    null,
  constraint menuItem
    unique (menuItem, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_acp_session
(
  sessionID        char(40)     default '' not null,
  packageID        int unsigned default 0  not null,
  userID           int unsigned default 0  not null,
  ipAddress        varchar(39)  default '' not null,
  userAgent        varchar(255) default '' not null,
  lastActivityTime int unsigned default 0  not null,
  requestURI       varchar(255) default '' not null,
  requestMethod    varchar(4)   default '' not null,
  username         varchar(255) default '' not null,
  primary key (sessionID, packageID)
)
  engine = MEMORY
    charset = utf8mb3;

create table wcf1_acp_session_access_log
(
  sessionAccessLogID int(10) auto_increment
        primary key,
  sessionLogID       int(10)      default 0  not null,
  packageID          int(10)      default 0  not null,
  ipAddress          varchar(39)  default '' not null,
  time               int(10)      default 0  not null,
  requestURI         varchar(255) default '' not null,
  requestMethod      varchar(4)   default '' not null,
  className          varchar(255) default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index sessionLogID
  on wcf1_acp_session_access_log (sessionLogID);

create table wcf1_acp_session_data
(
  sessionID        char(40) default '' not null
    primary key,
  userData         mediumtext          null,
  sessionVariables mediumtext          null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_acp_session_log
(
  sessionLogID     int(10) auto_increment
        primary key,
  sessionID        char(40)     default '' not null,
  userID           int(10)      default 0  not null,
  ipAddress        varchar(39)  default '' not null,
  hostname         varchar(255) default '' not null,
  userAgent        varchar(255) default '' not null,
  time             int(10)      default 0  not null,
  lastActivityTime int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index sessionID
  on wcf1_acp_session_log (sessionID);

create table wcf1_acp_template
(
  templateID   int unsigned auto_increment
        primary key,
  packageID    int unsigned default 0  not null,
  templateName varchar(255) default '' not null,
  constraint packageID
    unique (packageID, templateName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_acp_template_patch
(
  patchID    int unsigned auto_increment
        primary key,
  packageID  int unsigned        default 0 not null,
  templateID int unsigned        default 0 not null,
  success    tinyint(1) unsigned default 0 not null,
  fuzzFactor int unsigned        default 0 not null,
  patch      longtext                      null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_function
(
  functionID       int unsigned auto_increment
        primary key,
  packageID        int unsigned                  not null,
  functionName     varchar(255)                  not null,
  classPath        varchar(255)                  not null,
  executeAsCronjob tinyint(1) unsigned default 0 not null,
  saveSettings     tinyint(1) unsigned default 0 not null,
  constraint functionName
    unique (packageID, functionName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_function_to_cronjob
(
  functionID int unsigned not null,
  cronjobID  int unsigned not null,
  primary key (functionID, cronjobID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_iframe
(
  iframeID    int unsigned auto_increment
        primary key,
  menuItemID  int unsigned                                                                                       not null,
  url         varchar(255)                                                                                       not null,
  width       varchar(255)                                                                                       not null,
  height      varchar(255)                                                                                       not null,
  borderWidth varchar(255)                                                                                       not null,
  borderColor varchar(255)                                                                                       not null,
  borderStyle enum ('solid', 'dotted', 'dashed', 'double', 'groove', 'ridge', 'inset', 'outset') default 'solid' not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_option
(
  optionID          int unsigned auto_increment
        primary key,
  packageID         int unsigned        default 0  not null,
  optionName        varchar(255)        default '' not null,
  categoryName      varchar(255)        default '' not null,
  optionType        varchar(255)        default '' not null,
  optionValue       mediumtext                     null,
  validationPattern text                           null,
  selectOptions     mediumtext                     null,
  enableOptions     mediumtext                     null,
  showOrder         int unsigned        default 0  not null,
  hidden            tinyint(1) unsigned default 0  not null,
  permissions       text                           null,
  options           text                           null,
  constraint optionName
    unique (optionName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_option_category
(
  categoryID         int unsigned auto_increment
        primary key,
  packageID          int unsigned default 0  not null,
  functionID         int unsigned            not null,
  categoryName       varchar(255) default '' not null,
  parentCategoryName varchar(255) default '' not null,
  showOrder          int unsigned default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_admin_tools_spider
(
  spiderID         int unsigned auto_increment
        primary key,
  spiderIdentifier varchar(255) default '' null,
  spiderName       varchar(255) default '' null,
  spiderURL        varchar(255) default '' null,
  constraint spiderIdentifier
    unique (spiderIdentifier)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_attachment
(
  attachmentID     int(10) auto_increment
        primary key,
  packageID        int(10)      default 0  not null,
  containerID      int(10)      default 0  not null,
  containerType    varchar(255) default '' not null,
  userID           int(10)      default 0  not null,
  attachmentName   varchar(255) default '' not null,
  attachmentSize   int(10)      default 0  not null,
  fileType         varchar(255) default '' not null,
  isBinary         tinyint(1)   default 0  not null,
  isImage          tinyint(1)   default 0  not null,
  width            smallint(5)  default 0  not null,
  height           smallint(5)  default 0  not null,
  thumbnailType    varchar(255) default '' not null,
  thumbnailSize    int(10)      default 0  not null,
  thumbnailWidth   smallint(5)  default 0  not null,
  thumbnailHeight  smallint(5)  default 0  not null,
  downloads        int(10)      default 0  not null,
  lastDownloadTime int(10)      default 0  not null,
  sha1Hash         varchar(40)  default '' not null,
  idHash           varchar(40)  default '' not null,
  uploadTime       int(10)      default 0  not null,
  embedded         tinyint(1)   default 0  not null,
  showOrder        smallint(5)  default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_attachment (packageID, containerID, containerType);

create index packageID_2
  on wcf1_attachment (packageID, idHash, containerType);

create index userID
  on wcf1_attachment (userID, packageID);

create table wcf1_attachment_container_type
(
  containerTypeID int(10) auto_increment
        primary key,
  packageID       int(10)                 not null,
  containerType   varchar(255)            not null,
  isPrivate       tinyint(1)   default 0  not null,
  url             varchar(255) default '' not null,
  constraint packageID
    unique (packageID, containerType)
)
  engine = MyISAM
    charset = utf8mb3;

create index isPrivate
  on wcf1_attachment_container_type (isPrivate);

create table wcf1_avatar
(
  avatarID         int(10) auto_increment
        primary key,
  avatarCategoryID int(10)      default 0  not null,
  avatarName       varchar(255) default '' not null,
  avatarExtension  varchar(7)   default '' not null,
  width            smallint(5)  default 0  not null,
  height           smallint(5)  default 0  not null,
  groupID          int(10)      default 0  not null,
  neededPoints     int(10)      default 0  not null,
  userID           int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index avatarCategoryID
  on wcf1_avatar (avatarCategoryID);

create index userID
  on wcf1_avatar (userID, groupID);

create table wcf1_avatar_category
(
  avatarCategoryID int(10) auto_increment
        primary key,
  title            varchar(255) default '' not null,
  showOrder        mediumint(5) default 0  not null,
  groupID          int(10)      default 0  not null,
  neededPoints     int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_bbcode
(
  bbcodeID        int unsigned auto_increment
        primary key,
  bbcodeTag       varchar(255)        default ''    not null,
  packageID       int unsigned        default 0     not null,
  htmlOpen        varchar(255)        default ''    not null,
  htmlClose       varchar(255)        default ''    not null,
  textOpen        varchar(255)        default ''    not null,
  textClose       varchar(255)        default ''    not null,
  allowedChildren varchar(255)        default 'all' not null,
  className       varchar(255)        default ''    not null,
  wysiwyg         tinyint(1)          default 0     not null,
  wysiwygIcon     varchar(255)        default ''    not null,
  sourceCode      tinyint(1)          default 0     not null,
  disabled        tinyint(1) unsigned default 0     not null,
  constraint bbcodeTag
    unique (bbcodeTag)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_bbcode_attribute
(
  bbcodeID          int unsigned        default 0  not null,
  attributeNo       int unsigned        default 0  not null,
  attributeHtml     varchar(255)        default '' not null,
  attributeText     varchar(255)        default '' not null,
  validationPattern varchar(255)        default '' not null,
  required          tinyint(1) unsigned default 0  not null,
  useText           tinyint(1) unsigned default 0  not null,
  primary key (bbcodeID, attributeNo)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_cache_resource
(
  cacheResource varchar(255) not null
    primary key
)
  engine = MEMORY
    charset = utf8mb3;

create table wcf1_calendar
(
  calendarID   int(10) auto_increment
        primary key,
  userID       int(10)      default 0  not null,
  username     varchar(255)            not null,
  title        varchar(255) default '' not null,
  description  varchar(255) default '' not null,
  color        varchar(10)             not null,
  className    varchar(255) default '' not null,
  createTime   int(10)      default 0  not null,
  isSubscribed tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_calendar (userID);

create table wcf1_calendar_event
(
  eventID        int(10) auto_increment
        primary key,
  userID         int(10)      default 0  not null,
  username       varchar(255)            not null,
  calendarID     int(10)      default 0  not null,
  messageID      int(10)      default 0  not null,
  location       varchar(255) default '' not null,
  eventDate      text                    null,
  enableComments tinyint(1)   default 1  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_event (calendarID);

create index messageID
  on wcf1_calendar_event (messageID);

create table wcf1_calendar_event_date
(
  eventID       int(10)              not null,
  calendarID    int(10)    default 0 not null,
  startTime     int(10)    default 0 not null,
  endTime       int(10)    default 0 not null,
  repeatTime    int(10)    default 0 not null,
  repeatEndTime int(10)    default 0 not null,
  isFullDay     tinyint(1) default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_event_date (calendarID, startTime, endTime, repeatTime, repeatEndTime);

create index eventID
  on wcf1_calendar_event_date (eventID);

create table wcf1_calendar_event_message
(
  messageID     int(10) auto_increment
        primary key,
  eventID       int(10)      default 0  not null,
  userID        int(10)      default 0  not null,
  username      varchar(255) default '' not null,
  subject       varchar(255) default '' not null,
  message       mediumtext              null,
  time          int(10)      default 0  not null,
  ipAddress     varchar(15)  default '' not null,
  attachments   mediumint(5) default 0  not null,
  pollID        int(10)      default 0  not null,
  enableSmilies tinyint(1)   default 1  not null,
  enableHtml    tinyint(1)   default 0  not null,
  enableBBCodes tinyint(1)   default 1  not null,
  showSignature tinyint(1)   default 1  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index eventID
  on wcf1_calendar_event_message (eventID);

create fulltext index subject
    on wcf1_calendar_event_message (subject, message);

create table wcf1_calendar_event_notification
(
  eventID        int(10) default 0 not null,
  calendarID     int(10) default 0 not null,
  recipientID    int(10) default 0 not null,
  localStartTime int(10) default 0 not null,
  sendTime       int(10) default 0 not null,
  startTime      int(10) default 0 not null,
  primary key (eventID, calendarID, recipientID, startTime)
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_event_notification (calendarID, recipientID, localStartTime, sendTime);

create index calendarID_2
  on wcf1_calendar_event_notification (calendarID, recipientID);

create table wcf1_calendar_event_participation
(
  participationID int(10) auto_increment
        primary key,
  eventID         int(10)      default 0 not null,
  endTime         int(10)      default 0 not null,
  yesCount        mediumint(7) default 0 not null,
  noCount         mediumint(7) default 0 not null,
  maybeCount      mediumint(7) default 0 not null,
  maxParticipants mediumint(7) default 0 not null,
  isChangeable    tinyint(1)   default 1 not null,
  isPublic        tinyint(1)   default 1 not null,
  hideEvent       tinyint(1)   default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index eventID
  on wcf1_calendar_event_participation (eventID);

create index hideEvent
  on wcf1_calendar_event_participation (hideEvent);

create table wcf1_calendar_event_participation_to_user
(
  participationID int(10)                     default 0     not null,
  userID          int(10)                     default 0     not null,
  username        varchar(255)                default ''    not null,
  decision        enum ('yes', 'maybe', 'no') default 'yes' not null,
  decisionTime    int(10)                     default 0     not null,
  primary key (participationID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_calendar_event_participation_to_user (userID, decision);

create table wcf1_calendar_settings_to_user
(
  calendarID       int(10)                     default 0     not null,
  userID           int(10)                     default 0     not null,
  color            varchar(10)                               null,
  isEnabled        tinyint(1)                  default 1     not null,
  notification     enum ('off', 'email', 'pm') default 'off' not null,
  notificationTime int(10)                     default 3600  not null,
  primary key (userID, calendarID)
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_settings_to_user (calendarID);

create index notification
  on wcf1_calendar_settings_to_user (notification, isEnabled);

create table wcf1_calendar_subscription
(
  calendarID   int(10)                 not null,
  subscription varchar(255) default '' not null,
  lastUpdate   int(10)      default 0  not null,
  offline      int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_subscription (calendarID);

create index lastUpdate
  on wcf1_calendar_subscription (lastUpdate, offline);

create table wcf1_calendar_to_friend
(
  calendarID          int(10)    default 0 not null,
  friendID            int(10)    default 0 not null,
  canEditCalendar     tinyint(1) default 1 not null,
  canDeleteCalendar   tinyint(1) default 1 not null,
  canAddEvent         tinyint(1) default 1 not null,
  canEditEvent        tinyint(1) default 1 not null,
  canDeleteEvent      tinyint(1) default 1 not null,
  canEditOwnEvent     tinyint(1) default 1 not null,
  canDeleteOwnEvent   tinyint(1) default 1 not null,
  canAddComment       tinyint(1) default 1 not null,
  canEditComment      tinyint(1) default 1 not null,
  canDeleteComment    tinyint(1) default 1 not null,
  canEditOwnComment   tinyint(1) default 1 not null,
  canDeleteOwnComment tinyint(1) default 1 not null,
  primary key (friendID, calendarID)
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_to_friend (calendarID);

create table wcf1_calendar_to_group
(
  calendarID          int(10)    default 0 not null,
  groupID             int(10)    default 0 not null,
  canEditCalendar     tinyint(1) default 1 not null,
  canDeleteCalendar   tinyint(1) default 1 not null,
  canAddEvent         tinyint(1) default 1 not null,
  canEditEvent        tinyint(1) default 1 not null,
  canDeleteEvent      tinyint(1) default 1 not null,
  canEditOwnEvent     tinyint(1) default 1 not null,
  canDeleteOwnEvent   tinyint(1) default 1 not null,
  canAddComment       tinyint(1) default 1 not null,
  canEditComment      tinyint(1) default 1 not null,
  canDeleteComment    tinyint(1) default 1 not null,
  canEditOwnComment   tinyint(1) default 1 not null,
  canDeleteOwnComment tinyint(1) default 1 not null,
  primary key (groupID, calendarID)
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_to_group (calendarID);

create table wcf1_calendar_to_user
(
  calendarID          int(10)    default 0 not null,
  userID              int(10)    default 0 not null,
  canEditCalendar     tinyint(1) default 1 not null,
  canDeleteCalendar   tinyint(1) default 1 not null,
  canAddEvent         tinyint(1) default 1 not null,
  canEditEvent        tinyint(1) default 1 not null,
  canDeleteEvent      tinyint(1) default 1 not null,
  canEditOwnEvent     tinyint(1) default 1 not null,
  canDeleteOwnEvent   tinyint(1) default 1 not null,
  canAddComment       tinyint(1) default 1 not null,
  canEditComment      tinyint(1) default 1 not null,
  canDeleteComment    tinyint(1) default 1 not null,
  canEditOwnComment   tinyint(1) default 1 not null,
  canDeleteOwnComment tinyint(1) default 1 not null,
  primary key (userID, calendarID)
)
  engine = MyISAM
    charset = utf8mb3;

create index calendarID
  on wcf1_calendar_to_user (calendarID);

create table wcf1_captcha
(
  captchaID     int unsigned auto_increment
        primary key,
  captchaString varchar(255) default '' not null,
  captchaDate   int unsigned default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_chat_message
(
  messageID     int(10) auto_increment
        primary key,
  roomID        int(10)                       not null,
  senderID      int(10)                       not null,
  getterID      int(10)      default 0        not null,
  text          mediumtext                    not null,
  time          int(10)                       not null,
  type          tinyint(1)   default 0        not null,
  enablesmilies tinyint(1)   default 1        not null,
  enableHTML    tinyint(1)   default 0        not null,
  color         varchar(6)   default '000000' not null,
  color2        varchar(6)   default '000000' not null,
  username      varchar(255) default ''       null
)
  engine = MyISAM
    charset = utf8mb3;

create index getterID
  on wcf1_chat_message (getterID);

create index roomID
  on wcf1_chat_message (roomID);

create table wcf1_chat_room
(
  roomID    int(10) auto_increment
        primary key,
  name      varchar(255)         not null,
  topic     varchar(255)         not null,
  position  int(10)    default 0 not null,
  permanent tinyint(1) default 1 not null,
  userID    int(10)    default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index position
  on wcf1_chat_room (position);

create table wcf1_chat_room_invite
(
  roomID int(10)              not null,
  userID int(10)              not null,
  time   int(10)    default 0 not null,
  used   tinyint(1) default 0 not null,
  primary key (roomID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_chat_room_invite (userID);

create table wcf1_chat_room_suspension
(
  roomID int(10)           not null,
  userID int(10)           not null,
  mute   int(10) default 0 not null,
  ban    int(10) default 0 not null,
  primary key (roomID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_chat_room_suspension (userID);

create table wcf1_counter_update_type
(
  counterUpdateTypeID int(10) auto_increment
        primary key,
  packageID           int(10)      not null,
  counterUpdateType   varchar(255) not null,
  classFile           varchar(255) not null,
  constraint packageID
    unique (packageID, counterUpdateType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_cronjobs
(
  cronjobID     int unsigned auto_increment
        primary key,
  classPath     varchar(255) default ''  not null,
  packageID     int unsigned default 0   not null,
  description   varchar(255) default ''  not null,
  startMinute   varchar(255) default '*' not null,
  startHour     varchar(255) default '*' not null,
  startDom      varchar(255) default '*' not null,
  startMonth    varchar(255) default '*' not null,
  startDow      varchar(255) default '*' not null,
  lastExec      int unsigned default 0   not null,
  nextExec      int unsigned default 0   not null,
  execMultiple  tinyint      default 0   not null,
  active        tinyint      default 1   not null,
  canBeEdited   tinyint      default 1   not null,
  canBeDisabled tinyint      default 1   not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_cronjobs (packageID);

create table wcf1_cronjobs_log
(
  cronjobsLogID int unsigned auto_increment
        primary key,
  cronjobID     int unsigned default 0 not null,
  execTime      int(10)      default 0 not null,
  success       tinyint      default 0 not null,
  error         text                   null
)
  engine = MyISAM
    charset = utf8mb3;

create index cronjobID
  on wcf1_cronjobs_log (cronjobID);

create table wcf1_event_listener
(
  listenerID        int unsigned auto_increment
        primary key,
  packageID         int unsigned           default 0      not null,
  environment       enum ('user', 'admin') default 'user' not null,
  eventClassName    varchar(80)            default ''     not null,
  eventName         varchar(50)            default ''     not null,
  listenerClassFile varchar(200)           default ''     not null,
  inherit           tinyint(1) unsigned    default 0      not null,
  niceValue         tinyint(3)             default 0      not null,
  constraint packageID
    unique (packageID, environment, eventClassName, eventName, listenerClassFile)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_feed_entry
(
  entryID     int unsigned auto_increment
        primary key,
  sourceID    int unsigned default 0  not null,
  title       varchar(255) default '' not null,
  author      varchar(255) default '' not null,
  link        varchar(255) default '' not null,
  guid        varchar(255) default '' not null,
  pubDate     int unsigned default 0  not null,
  description mediumtext              null,
  constraint sourceID
    unique (sourceID, guid)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_feed_source
(
  sourceID    int unsigned auto_increment
        primary key,
  sourceName  varchar(255) default '' not null,
  sourceURL   varchar(255) default '' not null,
  packageID   int unsigned default 0  not null,
  lastUpdate  int unsigned default 0  not null,
  updateCycle int unsigned default 0  not null,
  constraint packageID
    unique (packageID, sourceName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_gmap_menu_item
(
  menuItemID     int unsigned auto_increment
        primary key,
  menuItem       varchar(255) default '' not null,
  parentMenuItem varchar(255) default '' not null,
  menuItemLink   varchar(255) default '' not null,
  menuItemIconM  varchar(255) default '' not null,
  menuItemIconL  varchar(255) default '' not null,
  showOrder      smallint(5)  default 0  not null,
  permissions    text                    null,
  options        text                    null,
  constraint menuItem
    unique (menuItem)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_gmap_user
(
  userID int unsigned not null
        primary key,
  pt     point        not null
)
  engine = MyISAM
    charset = utf8mb3;

create spatial index pt
    on wcf1_gmap_user (pt);

create table wcf1_group
(
  groupID           int unsigned auto_increment
        primary key,
  groupName         varchar(255)          default ''   not null,
  groupType         tinyint(1) unsigned   default 0    not null,
  groupDescription  text                               null,
  neededAge         smallint(5)           default 0    not null,
  neededPoints      int(10)               default 0    not null,
  userOnlineMarking varchar(255)          default '%s' not null,
  showOnTeamPage    tinyint(1) unsigned   default 0    not null,
  teamPagePosition  mediumint(5) unsigned default 0    not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_group_application
(
  applicationID      int(11) unsigned auto_increment
        primary key,
  userID             int(11) unsigned    default 0 not null,
  groupID            int(11) unsigned    default 0 not null,
  applicationTime    int unsigned        default 0 not null,
  reason             text                          null,
  reply              text                          null,
  applicationStatus  tinyint(1) unsigned default 0 not null,
  enableNotification tinyint(1) unsigned default 0 not null,
  groupLeaderID      int(11) unsigned    default 0 not null,
  constraint userID
    unique (userID, groupID)
)
  engine = MyISAM
    charset = utf8mb3;

create index groupID
  on wcf1_group_application (groupID, applicationStatus);

create table wcf1_group_leader
(
  groupID       int default 0 not null,
  leaderUserID  int default 0 not null,
  leaderGroupID int default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index groupID
  on wcf1_group_leader (groupID);

create index leaderGroupID
  on wcf1_group_leader (leaderGroupID, groupID);

create index leaderUserID
  on wcf1_group_leader (leaderUserID, groupID);

create table wcf1_group_option
(
  optionID          int unsigned auto_increment
        primary key,
  packageID         int unsigned default 0  not null,
  optionName        varchar(255) default '' not null,
  categoryName      varchar(255) default '' not null,
  optionType        varchar(255) default '' not null,
  defaultValue      mediumtext              null,
  validationPattern text                    null,
  enableOptions     mediumtext              null,
  showOrder         int unsigned default 0  not null,
  permissions       text                    null,
  options           text                    null,
  additionalData    mediumtext              null,
  constraint optionName
    unique (optionName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_group_option_category
(
  categoryID         int unsigned auto_increment
        primary key,
  packageID          int unsigned default 0  not null,
  categoryName       varchar(255) default '' not null,
  parentCategoryName varchar(255) default '' not null,
  showOrder          int unsigned default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_group_option_value
(
  groupID     int unsigned default 0 not null,
  optionID    int unsigned default 0 not null,
  optionValue mediumtext             not null,
  primary key (groupID, optionID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_help_item
(
  helpItemID     int unsigned auto_increment
        primary key,
  packageID      int unsigned default 0  not null,
  helpItem       varchar(255) default '' not null,
  parentHelpItem varchar(255) default '' not null,
  refererPattern varchar(255) default '' not null,
  showOrder      int unsigned default 0  not null,
  permissions    text                    null,
  options        text                    null,
  isDisabled     tinyint(1)   default 0  not null,
  constraint packageID
    unique (packageID, helpItem)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_language
(
  languageID       int unsigned auto_increment
        primary key,
  languageCode     varchar(20)         default '' not null,
  languageEncoding varchar(20)         default '' not null,
  isDefault        tinyint(1) unsigned default 0  not null,
  hasContent       tinyint(1) unsigned default 0  not null,
  constraint languageCode
    unique (languageCode)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_language_category
(
  languageCategoryID int unsigned auto_increment
        primary key,
  languageCategory   varchar(255) default '' not null,
  constraint languageCategory
    unique (languageCategory)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_language_item
(
  languageItemID          int unsigned auto_increment
        primary key,
  languageID              int unsigned default 0  not null,
  languageItem            varchar(255) default '' not null,
  languageItemValue       mediumtext              not null,
  languageHasCustomValue  tinyint(1)   default 0  not null,
  languageCustomItemValue mediumtext              null,
  languageUseCustomValue  tinyint(1)   default 0  not null,
  languageCategoryID      int unsigned default 0  not null,
  packageID               int unsigned default 0  not null,
  constraint languageItem
    unique (languageItem, packageID, languageID)
)
  engine = MyISAM
    charset = utf8mb3;

create index languageHasCustomValue
  on wcf1_language_item (languageHasCustomValue);

create index languageID
  on wcf1_language_item (languageID, languageCategoryID, packageID);

create table wcf1_language_to_packages
(
  languageID int unsigned default 0 not null,
  packageID  int unsigned default 0 not null,
  primary key (languageID, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_moderation_type
(
  moderationTypeID int(10) auto_increment
        primary key,
  packageID        int(10) default 0 not null,
  moderationType   varchar(255)      not null,
  classFile        varchar(255)      not null,
  constraint packageID
    unique (packageID, moderationType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_moderationcp_menu_item
(
  menuItemID     int(10) auto_increment
        primary key,
  packageID      int(10)      default 0  not null,
  menuItem       varchar(255) default '' not null,
  parentMenuItem varchar(255) default '' not null,
  menuItemLink   varchar(255) default '' not null,
  menuItemIcon   varchar(255) default '' not null,
  showOrder      int(10)      default 0  not null,
  permissions    text                    null,
  options        text                    null,
  constraint menuItem
    unique (menuItem, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_option
(
  optionID          int unsigned auto_increment
        primary key,
  packageID         int unsigned        default 0  not null,
  optionName        varchar(255)        default '' not null,
  categoryName      varchar(255)        default '' not null,
  optionType        varchar(255)        default '' not null,
  optionValue       mediumtext                     null,
  validationPattern text                           null,
  selectOptions     mediumtext                     null,
  enableOptions     mediumtext                     null,
  showOrder         int unsigned        default 0  not null,
  hidden            tinyint(1) unsigned default 0  not null,
  permissions       text                           null,
  options           text                           null,
  additionalData    mediumtext                     null,
  constraint optionName
    unique (optionName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_option_category
(
  categoryID         int unsigned auto_increment
        primary key,
  packageID          int unsigned default 0  not null,
  categoryName       varchar(255) default '' not null,
  parentCategoryName varchar(255) default '' not null,
  showOrder          int unsigned default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package
(
  packageID          int unsigned auto_increment
        primary key,
  package            varchar(255)        default '' not null,
  packageDir         varchar(255)        default '' not null,
  packageName        varchar(255)        default '' not null,
  instanceName       varchar(255)        default '' not null,
  instanceNo         int unsigned        default 1  not null,
  packageDescription varchar(255)        default '' not null,
  packageVersion     varchar(255)        default '' not null,
  packageDate        int unsigned        default 0  not null,
  installDate        int(10)             default 0  not null,
  updateDate         int(10)             default 0  not null,
  packageURL         varchar(255)        default '' not null,
  parentPackageID    int unsigned        default 0  not null,
  isUnique           tinyint(1) unsigned default 0  not null,
  standalone         tinyint(1) unsigned default 0  not null,
  author             varchar(255)        default '' not null,
  authorURL          varchar(255)        default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index package
  on wcf1_package (package);

create table wcf1_package_dependency
(
  packageID  int unsigned default 0 not null,
  dependency int unsigned default 0 not null,
  priority   int unsigned default 0 not null,
  primary key (packageID, dependency)
)
  engine = MyISAM
    charset = utf8mb3;

create index dependency
  on wcf1_package_dependency (dependency);

create table wcf1_package_exclusion
(
  packageID              int(10)      default 0  not null,
  excludedPackage        varchar(255) default '' not null,
  excludedPackageVersion varchar(255) default '' not null,
  primary key (packageID, excludedPackage)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_installation_file_log
(
  packageID int unsigned default 0  not null,
  filename  varchar(255) default '' not null,
  primary key (packageID, filename)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_installation_plugin
(
  pluginName varchar(255)        default '' not null
    primary key,
  packageID  int unsigned        default 0  not null,
  priority   tinyint(1) unsigned default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_installation_queue
(
  queueID             int unsigned auto_increment
        primary key,
  parentQueueID       int unsigned                                        default 0         not null,
  processNo           int unsigned                                        default 0         not null,
  userID              int unsigned                                        default 0         not null,
  package             varchar(255)                                        default ''        not null,
  packageID           int unsigned                                        default 0         not null,
  archive             varchar(255)                                        default ''        not null,
  action              enum ('install', 'update', 'uninstall', 'rollback') default 'install' not null,
  cancelable          tinyint(1) unsigned                                 default 1         not null,
  done                tinyint(1) unsigned                                 default 0         not null,
  confirmInstallation tinyint(1) unsigned                                 default 0         not null,
  packageType         enum ('default', 'requirement', 'optional')         default 'default' not null,
  installationType    enum ('install', 'setup', 'other')                  default 'other'   not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_installation_sql_log
(
  packageID int unsigned default 0  not null,
  sqlTable  varchar(100) default '' not null,
  sqlColumn varchar(100) default '' not null,
  sqlIndex  varchar(100) default '' not null,
  primary key (packageID, sqlTable, sqlColumn, sqlIndex)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_requirement
(
  packageID   int unsigned default 0 not null,
  requirement int unsigned default 0 not null,
  primary key (packageID, requirement)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_requirement_map
(
  packageID   int unsigned default 0 not null,
  requirement int unsigned default 0 not null,
  level       int unsigned default 0 not null,
  primary key (packageID, requirement)
)
  engine = MyISAM
    charset = utf8mb3;

create index requirement
  on wcf1_package_requirement_map (requirement);

create table wcf1_package_update
(
  packageUpdateID       int unsigned auto_increment
        primary key,
  packageUpdateServerID int unsigned default 0  not null,
  package               varchar(255) default '' not null,
  packageName           varchar(255) default '' not null,
  packageDescription    varchar(255) default '' not null,
  author                varchar(255) default '' not null,
  authorURL             varchar(255) default '' not null,
  standalone            tinyint(1)   default 0  not null,
  plugin                varchar(255) default '' not null,
  constraint packageUpdateServerID
    unique (packageUpdateServerID, package)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_update_exclusion
(
  packageUpdateVersionID int(10)      default 0  not null,
  excludedPackage        varchar(255) default '' not null,
  excludedPackageVersion varchar(255) default '' not null,
  primary key (packageUpdateVersionID, excludedPackage)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_update_fromversion
(
  packageUpdateVersionID int unsigned default 0  not null,
  fromversion            varchar(50)  default '' not null,
  constraint packageUpdateVersionID
    unique (packageUpdateVersionID, fromversion)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_update_requirement
(
  packageUpdateVersionID int unsigned default 0  not null,
  package                varchar(255) default '' not null,
  minversion             varchar(50)  default '' not null,
  constraint packageUpdateVersionID
    unique (packageUpdateVersionID, package)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_update_server
(
  packageUpdateServerID int unsigned auto_increment
        primary key,
  server                varchar(255)        default '' not null,
  status                varchar(10)         default '' not null,
  statusUpdate          tinyint(1) unsigned default 1  not null,
  errorText             text                           null,
  updatesFile           tinyint(1) unsigned default 0  not null,
  timestamp             int unsigned        default 0  not null,
  htUsername            varchar(50)         default '' not null,
  htPassword            varchar(40)         default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_package_update_version
(
  packageUpdateVersionID int unsigned auto_increment
        primary key,
  packageUpdateID        int unsigned default 0  not null,
  packageVersion         varchar(50)  default '' not null,
  updateType             varchar(10)  default '' not null,
  timestamp              int unsigned default 0  not null,
  file                   varchar(255) default '' not null,
  constraint packageUpdateID
    unique (packageUpdateID, packageVersion)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_page_location
(
  locationID      int unsigned auto_increment
        primary key,
  locationPattern varchar(255) default '' not null,
  locationName    varchar(255) default '' not null,
  packageID       int(10)      default 0  not null,
  classPath       varchar(255) default '' not null,
  constraint packageID
    unique (packageID, locationName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_page_menu_item
(
  menuItemID    int(10) auto_increment
        primary key,
  packageID     int(10)                   default 0        not null,
  menuItem      varchar(255)              default ''       not null,
  menuItemLink  varchar(255)              default ''       not null,
  menuItemIconS varchar(255)              default ''       not null,
  menuItemIconM varchar(255)              default ''       not null,
  menuPosition  enum ('header', 'footer') default 'header' not null,
  showOrder     int(10)                   default 0        not null,
  permissions   text                                       null,
  options       text                                       null,
  isDisabled    tinyint(1)                default 0        not null,
  constraint packageID
    unique (packageID, menuItem)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_pm
(
  pmID          int unsigned auto_increment
        primary key,
  parentPmID    int unsigned        default 0  not null,
  userID        int unsigned        default 0  not null,
  username      varchar(255)        default '' not null,
  subject       varchar(255)        default '' not null,
  message       mediumtext                     not null,
  time          int unsigned        default 0  not null,
  attachments   int unsigned        default 0  not null,
  enableSmilies tinyint(1) unsigned default 1  not null,
  enableHtml    tinyint(1) unsigned default 0  not null,
  enableBBCodes tinyint(1) unsigned default 1  not null,
  showSignature tinyint(1) unsigned default 0  not null,
  saveInOutbox  tinyint(1) unsigned default 0  not null,
  isDraft       tinyint(1) unsigned default 0  not null,
  isViewedByAll tinyint(1) unsigned default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index parentPmID
  on wcf1_pm (parentPmID);

create fulltext index subject
    on wcf1_pm (subject, message);

create index userID
  on wcf1_pm (userID, saveInOutbox, pmID);

create index userID_2
  on wcf1_pm (userID, isDraft);

create table wcf1_pm_folder
(
  folderID   int unsigned auto_increment
        primary key,
  userID     int unsigned                                     default 0        not null,
  folderName varchar(255)                                     default ''       not null,
  color      enum ('yellow', 'red', 'blue', 'green', 'white') default 'yellow' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_pm_folder (userID);

create table wcf1_pm_hash
(
  pmID        int unsigned,
  time        int unsigned default 0  not null,
  messageHash varchar(40)  default '' not null
    primary key
)
  engine = MyISAM
    charset = utf8mb3;

create index pmID
  on wcf1_pm_hash (pmID);

alter table wcf1_pm_hash
  modify pmID int unsigned auto_increment;

create table wcf1_pm_rule
(
  ruleID          int(10) auto_increment
        primary key,
  userID          int(10)                                not null,
  title           varchar(255)              default ''   not null,
  logicalOperator enum ('or', 'and', 'nor') default 'or' not null,
  ruleAction      varchar(255)                           not null,
  ruleDestination varchar(255)              default ''   not null,
  disabled        tinyint(1)                default 0    not null
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_pm_rule (userID);

create table wcf1_pm_rule_action
(
  ruleActionID        int(10) auto_increment
        primary key,
  packageID           int(10) default 0 not null,
  ruleAction          varchar(255)      not null,
  ruleActionClassFile varchar(255)      not null,
  constraint ruleAction
    unique (ruleAction)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_pm_rule_condition
(
  ruleConditionID    int(10) auto_increment
        primary key,
  ruleID             int(10)                 not null,
  ruleConditionType  varchar(255) default '' not null,
  ruleCondition      varchar(255) default '' not null,
  ruleConditionValue varchar(255) default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index ruleID
  on wcf1_pm_rule_condition (ruleID);

create table wcf1_pm_rule_condition_type
(
  ruleConditionTypeID        int(10) auto_increment
        primary key,
  packageID                  int(10) default 0 not null,
  ruleConditionType          varchar(255)      not null,
  ruleConditionTypeClassFile varchar(255)      not null,
  constraint ruleConditionType
    unique (ruleConditionType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_pm_to_user
(
  pmID            int unsigned        default 0  not null,
  recipientID     int unsigned        default 0  not null,
  recipient       varchar(255)        default '' not null,
  folderID        int unsigned        default 0  not null,
  isDeleted       tinyint(1) unsigned default 0  not null,
  isViewed        int unsigned        default 0  not null,
  isReplied       tinyint(1) unsigned default 0  not null,
  isForwarded     tinyint(1) unsigned default 0  not null,
  isBlindCopy     tinyint(1) unsigned default 0  not null,
  userWasNotified tinyint(1) unsigned default 0  not null,
  primary key (pmID, recipientID)
)
  engine = MyISAM
    charset = utf8mb3;

create index pmID
  on wcf1_pm_to_user (pmID, isBlindCopy, recipient);

create index recipientID
  on wcf1_pm_to_user (recipientID, isDeleted, folderID);

create table wcf1_poll
(
  pollID             int unsigned auto_increment
        primary key,
  packageID          int unsigned          default 0  not null,
  messageID          int unsigned          default 0  not null,
  messageType        varchar(255)          default '' not null,
  question           varchar(255)          default '' not null,
  time               int unsigned          default 0  not null,
  endTime            int unsigned          default 0  not null,
  choiceCount        tinyint unsigned      default 0  not null,
  votes              mediumint(7) unsigned default 0  not null,
  votesNotChangeable tinyint(1) unsigned   default 0  not null,
  sortByResult       tinyint(1) unsigned   default 0  not null,
  isPublic           tinyint(1)            default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index messageID
  on wcf1_poll (messageID, messageType, packageID);

create table wcf1_poll_option
(
  pollOptionID int unsigned auto_increment
        primary key,
  pollID       int unsigned          default 0  not null,
  pollOption   varchar(255)          default '' not null,
  votes        mediumint(7) unsigned default 0  not null,
  showOrder    tinyint unsigned      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index pollID
  on wcf1_poll_option (pollID);

create table wcf1_poll_option_vote
(
  pollID       int unsigned default 0  not null,
  pollOptionID int unsigned default 0  not null,
  userID       int unsigned default 0  not null,
  ipAddress    varchar(15)  default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index pollID
  on wcf1_poll_option_vote (pollID, userID);

create index pollID_2
  on wcf1_poll_option_vote (pollID, ipAddress);

create index pollOptionID
  on wcf1_poll_option_vote (pollOptionID, userID);

create index pollOptionID_2
  on wcf1_poll_option_vote (pollOptionID, ipAddress);

create table wcf1_poll_vote
(
  pollID       int unsigned        default 0  not null,
  isChangeable tinyint(1) unsigned default 1  not null,
  userID       int unsigned        default 0  not null,
  ipAddress    varchar(15)         default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index pollID
  on wcf1_poll_vote (pollID, userID);

create index pollID_2
  on wcf1_poll_vote (pollID, ipAddress);

create table wcf1_rateable_object
(
  objectName       varchar(255) default '' not null,
  tableName        varchar(255) default '' not null,
  objectIdentifier varchar(255) default '' not null,
  permissions      text                    not null,
  packageID        int(10)      default 0  not null,
  constraint objectName
    unique (objectName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_rating
(
  objectID   int(10)      default 0  not null,
  objectName varchar(255) default '' not null,
  packageID  int(10)      default 0  not null,
  rating     int(10)      default 0  not null,
  userID     int(10)      default 0  not null,
  ipAddress  varchar(15)  default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_rating (packageID, objectName, objectID, userID);

create index packageID_2
  on wcf1_rating (packageID, objectName, objectID, ipAddress);

create table wcf1_rule_item
(
  ruleItemID     int unsigned auto_increment
        primary key,
  rulesetID      int unsigned default 0  not null,
  parentRuleItem varchar(255) default '' not null,
  ruleItem       varchar(255) default '' not null,
  showOrder      int unsigned default 0  not null,
  options        text                    null
)
  engine = MyISAM
    charset = utf8mb3;

create index rulesetID
  on wcf1_rule_item (rulesetID);

create table wcf1_ruleset
(
  rulesetID   int(10) auto_increment
        primary key,
  name        varchar(255) default '' not null,
  undeletable smallint(1)  default 0  not null,
  lastUpdate  int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index name
  on wcf1_ruleset (name);

create index name_2
  on wcf1_ruleset (name, rulesetID);

create table wcf1_ruleset_to_package
(
  rulesetID int(10) default 0 not null,
  packageID int(10) default 0 not null,
  constraint rulesetID
    unique (rulesetID, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_ruleset_to_package (packageID);

create index rulesetID_2
  on wcf1_ruleset_to_package (rulesetID);

create table wcf1_ruleset_to_user
(
  userID    int(10) default 0 not null,
  rulesetID int(10) default 0 not null,
  constraint userID
    unique (userID, rulesetID)
)
  engine = MyISAM
    charset = utf8mb3;

create index rulesetID
  on wcf1_ruleset_to_user (rulesetID);

create table wcf1_search
(
  searchID   int unsigned auto_increment
        primary key,
  userID     int unsigned default 0  not null,
  searchData mediumtext              not null,
  searchDate int unsigned default 0  not null,
  searchType varchar(255) default '' not null,
  searchHash char(40)     default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index searchHash
  on wcf1_search (searchHash);

create table wcf1_searchable_message_type
(
  typeID    int unsigned auto_increment
        primary key,
  typeName  varchar(255) default '' not null,
  classPath varchar(255) default '' not null,
  packageID int unsigned default 0  not null,
  constraint packageID
    unique (packageID, typeName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_session
(
  sessionID          char(40)     default '' not null
    primary key,
  packageID          int unsigned default 0  not null,
  userID             int unsigned default 0  not null,
  ipAddress          varchar(39)  default '' not null,
  userAgent          varchar(255) default '' not null,
  lastActivityTime   int unsigned default 0  not null,
  requestURI         varchar(255) default '' not null,
  requestMethod      varchar(4)   default '' not null,
  username           varchar(255) default '' not null,
  spiderID           int unsigned default 0  not null,
  boardID            int unsigned default 0  not null,
  threadID           int unsigned default 0  not null,
  filebaseCategoryID int(10)      default 0  not null,
  filebaseEntryID    int(10)      default 0  not null
)
  engine = MEMORY
    charset = utf8mb3;

create index packageID
  on wcf1_session (packageID, lastActivityTime, spiderID);

create index userID
  on wcf1_session (userID);

create table wcf1_session_data
(
  sessionID        char(40) default '' not null
    primary key,
  userData         mediumtext          null,
  sessionVariables mediumtext          null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_smiley
(
  smileyID         int(10) auto_increment
        primary key,
  packageID        int(10)      default 0  not null,
  smileyCategoryID int(10)      default 0  not null,
  smileyPath       varchar(255) default '' not null,
  smileyTitle      varchar(255) default '' not null,
  smileyCode       varchar(255) default '' not null,
  showOrder        mediumint(5) default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index smileyCategoryID
  on wcf1_smiley (smileyCategoryID);

create table wcf1_smiley_category
(
  smileyCategoryID int(10) auto_increment
        primary key,
  title            varchar(255) default '' not null,
  showOrder        mediumint(5) default 0  not null,
  disabled         tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_social_bookmark_provider
(
  providerID    int(10) auto_increment
        primary key,
  title         varchar(255) default '' not null,
  url           varchar(255) default '' not null,
  providerImage varchar(255) default '' not null,
  showOrder     smallint(5)  default 0  not null,
  enabled       tinyint(1)   default 1  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index enabled
  on wcf1_social_bookmark_provider (enabled);

create table wcf1_spider
(
  spiderID         int unsigned auto_increment
        primary key,
  spiderIdentifier varchar(255) default '' null,
  spiderName       varchar(255) default '' null,
  spiderURL        varchar(255) default '' null,
  constraint spiderIdentifier
    unique (spiderIdentifier)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_stat_type
(
  statTypeID    int(10) auto_increment
        primary key,
  packageID     int(10)                 not null,
  typeName      varchar(255)            not null,
  tableName     varchar(255)            not null,
  dateFieldName varchar(255)            not null,
  userFieldName varchar(255) default '' not null,
  constraint packageID
    unique (packageID, typeName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_style
(
  styleID          int(10) auto_increment
        primary key,
  packageID        int(10)      default 0            not null,
  styleName        varchar(255) default ''           not null,
  templatePackID   int(10)      default 0            not null,
  isDefault        tinyint(1)   default 0            not null,
  disabled         tinyint(1)   default 0            not null,
  styleDescription text                              null,
  styleVersion     varchar(255) default ''           not null,
  styleDate        char(10)     default '0000-00-00' not null,
  image            varchar(255) default ''           not null,
  copyright        varchar(255) default ''           not null,
  license          varchar(255) default ''           not null,
  authorName       varchar(255) default ''           not null,
  authorURL        varchar(255) default ''           not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_style_to_package
(
  styleID   int(10)              not null,
  packageID int(10)              not null,
  isDefault tinyint(1) default 0 not null,
  disabled  tinyint(1) default 0 not null,
  constraint styleID
    unique (styleID, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_style_variable
(
  styleID       int(10)                not null,
  variableName  varchar(50) default '' not null,
  variableValue mediumtext             null,
  constraint styleID
    unique (styleID, variableName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_style_variable_to_attribute
(
  packageID     int(10)      default 0  not null,
  cssSelector   varchar(200) default '' not null,
  attributeName varchar(50)  default '' not null,
  variableName  varchar(50)  default '' not null,
  constraint packageID
    unique (packageID, cssSelector, attributeName, variableName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_tag
(
  tagID      int(10) auto_increment
        primary key,
  languageID int(10)      default 0  not null,
  name       varchar(255) default '' not null,
  constraint languageID
    unique (languageID, name)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_tag_taggable
(
  taggableID int(10) auto_increment
        primary key,
  name       varchar(255) default '' not null,
  classPath  varchar(255) default '' not null,
  packageID  int(10)      default 0  not null,
  constraint name
    unique (name, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_tag_to_object
(
  objectID   int(10) default 0 not null,
  tagID      int(10) default 0 not null,
  taggableID int(10) default 0 not null,
  time       int(10) default 0 not null,
  languageID int(10) default 0 not null,
  primary key (taggableID, languageID, objectID, tagID)
)
  engine = MyISAM
    charset = utf8mb3;

create index tagID
  on wcf1_tag_to_object (tagID, taggableID);

create index taggableID
  on wcf1_tag_to_object (taggableID, languageID, tagID);

create table wcf1_template
(
  templateID     int(10) auto_increment
        primary key,
  packageID      int(10)      default 0  not null,
  templateName   varchar(255) default '' not null,
  templatePackID int(10)      default 0  not null,
  obsolete       tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_template (packageID, templateName);

create index packageID_2
  on wcf1_template (packageID, templatePackID, templateName);

create table wcf1_template_pack
(
  templatePackID         int(10) auto_increment
        primary key,
  parentTemplatePackID   int(10)      default 0  not null,
  templatePackName       varchar(255) default '' not null,
  templatePackFolderName varchar(255) default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_template_patch
(
  patchID    int unsigned auto_increment
        primary key,
  packageID  int unsigned        default 0 not null,
  templateID int unsigned        default 0 not null,
  success    tinyint(1) unsigned default 0 not null,
  fuzzFactor int unsigned        default 0 not null,
  patch      longtext                      null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_todo_entrys
(
  todoID                      int unsigned auto_increment
        primary key,
  creatorID                   int unsigned        default 0  not null,
  affectedUserID              int unsigned        default 0  not null,
  creationTime                int unsigned        default 0  not null,
  deadlineTime                int unsigned        default 0  not null,
  title                       varchar(255)        default '' not null,
  description                 text                           not null,
  stateID                     int unsigned        default 0  not null,
  lastEditorID                int unsigned                   null,
  lastEditTime                int unsigned        default 0  not null,
  assignedUserID              int unsigned        default 0  not null,
  newNotification             tinyint(1) unsigned default 1  not null,
  deadlineReachedNotification tinyint(1) unsigned default 1  not null,
  deleted                     tinyint(1) unsigned default 0  not null,
  archived                    tinyint(1) unsigned default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_todo_states
(
  stateID            int unsigned auto_increment
        primary key,
  title              varchar(255) default '' not null,
  sortOrder          int unsigned            not null,
  showAsTab          tinyint(1)   default 0  not null,
  iconBeforeDeadline varchar(255)            null,
  iconAfterDeadline  varchar(255)            null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user
(
  userID                     int unsigned auto_increment
        primary key,
  username                   varchar(255)        default ''       not null,
  email                      varchar(255)        default ''       not null,
  password                   varchar(40)         default ''       not null,
  salt                       varchar(40)         default ''       not null,
  languageID                 int unsigned        default 0        not null,
  registrationDate           int unsigned        default 0        not null,
  styleID                    int(10)             default 0        not null,
  activationCode             int unsigned        default 0        not null,
  registrationIpAddress      varchar(15)         default ''       not null,
  lastLostPasswordRequest    int unsigned        default 0        not null,
  lostPasswordKey            varchar(40)         default ''       not null,
  newEmail                   varchar(255)        default ''       not null,
  reactivationCode           int unsigned        default 0        not null,
  oldUsername                varchar(255)        default ''       not null,
  lastUsernameChange         int unsigned        default 0        not null,
  quitStarted                int unsigned        default 0        not null,
  banned                     tinyint(1) unsigned default 0        not null,
  banReason                  mediumtext                           null,
  rankID                     int unsigned        default 0        not null,
  userTitle                  varchar(255)        default ''       not null,
  activityPoints             int unsigned        default 0        not null,
  avatarID                   int unsigned        default 0        not null,
  gravatar                   varchar(255)        default ''       not null,
  disableAvatar              tinyint(1)          default 0        not null,
  disableAvatarReason        text                                 null,
  lastActivityTime           int unsigned        default 0        not null,
  profileHits                int unsigned        default 0        not null,
  signature                  text                                 null,
  signatureCache             text                                 null,
  enableSignatureSmilies     tinyint(1)          default 1        not null,
  enableSignatureHtml        tinyint(1)          default 0        not null,
  enableSignatureBBCodes     tinyint(1)          default 1        not null,
  disableSignature           tinyint(1)          default 0        not null,
  disableSignatureReason     text                                 null,
  pmTotalCount               int unsigned        default 0        not null,
  pmUnreadCount              int unsigned        default 0        not null,
  pmOutstandingNotifications int unsigned        default 0        not null,
  userOnlineGroupID          int unsigned        default 0        not null,
  notificationFlags          text                                 null,
  wqmLastUpdate              int unsigned        default 0        not null,
  wqmHasNew                  tinyint(1) unsigned default 0        not null,
  chatlastroom               int(10)             default 0        not null,
  chatlastactivity           int(10)             default 0        not null,
  chataway                   varchar(25)         default ''       not null,
  chatcolor                  varchar(6)          default '000000' not null,
  chatcolor2                 varchar(6)          default '000000' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index activationCode
  on wcf1_user (activationCode);

create index activityPoints
  on wcf1_user (activityPoints);

create index banned_user
  on wcf1_user (banned, disableSignature);

create index chatlastroom
  on wcf1_user (chatlastroom, chatlastactivity);

create index registrationDate
  on wcf1_user (registrationDate);

create index registrationIpAddress
  on wcf1_user (registrationIpAddress, registrationDate);

create index styleID
  on wcf1_user (styleID);

create index userRegistrationDate
  on wcf1_user (registrationDate, userID);

create index username
  on wcf1_user (username);

create table wcf1_user_activity_point
(
  userID         int unsigned default 0 not null,
  packageID      int unsigned default 0 not null,
  activityPoints int unsigned default 0 not null,
  constraint userID
    unique (userID, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_user_activity_point (packageID);

create table wcf1_user_blacklist
(
  userID      int unsigned not null,
  blackUserID int unsigned not null,
  constraint userID
    unique (userID, blackUserID)
)
  engine = MyISAM
    charset = utf8mb3;

create index blackUserID
  on wcf1_user_blacklist (blackUserID);

create table wcf1_user_failed_login
(
  failedLoginID int(10) auto_increment
        primary key,
  environment   enum ('user', 'admin') default 'user' not null,
  userID        int(10)                default 0      not null,
  username      varchar(255)           default ''     not null,
  time          int(10)                default 0      not null,
  ipAddress     varchar(15)            default ''     not null,
  userAgent     varchar(255)           default ''     not null
)
  engine = MyISAM
    charset = utf8mb3;

create index ipAddress
  on wcf1_user_failed_login (ipAddress);

create index time
  on wcf1_user_failed_login (time);

create index userID
  on wcf1_user_failed_login (userID);

create table wcf1_user_guestbook
(
  entryID              int(10) auto_increment
        primary key,
  ownerID              int(10)                 not null,
  userID               int(10)      default 0  not null,
  username             varchar(255) default '' not null,
  message              mediumtext              null,
  time                 int(10)      default 0  not null,
  enableSmilies        tinyint(1)   default 1  not null,
  enableHtml           tinyint(1)   default 0  not null,
  enableBBCodes        tinyint(1)   default 1  not null,
  comment              mediumtext              null,
  commentTime          int(10)      default 0  not null,
  enableCommentSmilies tinyint(1)   default 1  not null,
  enableCommentHtml    tinyint(1)   default 0  not null,
  enableCommentBBCodes tinyint(1)   default 1  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index ownerID
  on wcf1_user_guestbook (ownerID);

create table wcf1_user_guestbook_hash
(
  entryID     int(10)                not null,
  time        int(10)     default 0  not null,
  messageHash varchar(40) default '' not null
    primary key
)
  engine = MyISAM
    charset = utf8mb3;

create index entryID
  on wcf1_user_guestbook_hash (entryID);

create table wcf1_user_infraction_suspension
(
  suspensionID   int(10) auto_increment
        primary key,
  packageID      int(10)      default 0  not null,
  title          varchar(255) default '' not null,
  points         smallint(5)  default 0  not null,
  expires        int(10)      default 0  not null,
  suspensionType varchar(255) default '' not null,
  suspensionData mediumtext              null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_user_infraction_suspension (packageID);

create table wcf1_user_infraction_suspension_to_user
(
  userSuspensionID int(10) auto_increment
        primary key,
  packageID        int(10)    default 0 not null,
  userID           int(10)    default 0 not null,
  suspensionID     int(10)    default 0 not null,
  time             int(10)    default 0 not null,
  expires          int(10)    default 0 not null,
  revoked          tinyint(1) default 0 not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_user_infraction_suspension_to_user (packageID);

create index userID
  on wcf1_user_infraction_suspension_to_user (userID);

create table wcf1_user_infraction_suspension_type
(
  suspensionTypeID int(10) auto_increment
        primary key,
  packageID        int(10) default 0 not null,
  suspensionType   varchar(255)      not null,
  classFile        varchar(255)      not null,
  constraint packageID
    unique (packageID, suspensionType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_infraction_warning
(
  warningID int(10) auto_increment
        primary key,
  packageID int(10)      default 0  not null,
  title     varchar(255) default '' not null,
  points    smallint(5)  default 0  not null,
  expires   int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_user_infraction_warning (packageID);

create table wcf1_user_infraction_warning_object_type
(
  objectTypeID int(10) auto_increment
        primary key,
  packageID    int(10)      not null,
  objectType   varchar(255) not null,
  classFile    varchar(255) not null,
  constraint packageID
    unique (packageID, objectType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_infraction_warning_to_user
(
  userWarningID int(10) auto_increment
        primary key,
  packageID     int(10)      default 0  not null,
  objectID      int(10)      default 0  not null,
  objectType    varchar(255) default '' not null,
  userID        int(10)      default 0  not null,
  judgeID       int(10)      default 0  not null,
  warningID     int(10)      default 0  not null,
  time          int(10)      default 0  not null,
  title         varchar(255) default '' not null,
  points        smallint(5)  default 0  not null,
  expires       int(10)      default 0  not null,
  reason        mediumtext              null
)
  engine = MyISAM
    charset = utf8mb3;

create index judgeID
  on wcf1_user_infraction_warning_to_user (judgeID);

create index packageID
  on wcf1_user_infraction_warning_to_user (packageID, objectID, objectType);

create index userID
  on wcf1_user_infraction_warning_to_user (userID);

create index warningID
  on wcf1_user_infraction_warning_to_user (warningID);

create table wcf1_user_memo
(
  memoID   int(10) auto_increment
        primary key,
  userID   int(10)      default 0  not null,
  folderID int(10)      default 0  not null,
  username varchar(255) default '' not null,
  subject  varchar(255) default '' not null,
  message  mediumtext              null,
  time     int(10)      default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index folderID
  on wcf1_user_memo (folderID);

create fulltext index subject
    on wcf1_user_memo (subject, message);

create index userID
  on wcf1_user_memo (userID);

create table wcf1_user_memo_folder
(
  folderID int(10) auto_increment
        primary key,
  userID   int(10)      default 0  not null,
  title    varchar(255) default '' not null
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_user_memo_folder (userID);

create table wcf1_user_notification
(
  notificationID   int(10) auto_increment
        primary key,
  userID           int(10)      default 0  not null,
  packageID        int(10)      default 0  not null,
  objectType       varchar(255) default '' not null,
  objectID         int(10)      default 0  not null,
  eventName        varchar(255) default '' not null,
  time             int(10)      default 0  not null,
  shortOutput      varchar(255)            null,
  mediumOutput     text                    null,
  longOutput       text                    null,
  confirmed        tinyint(1)              not null,
  confirmationTime int(10)      default 0  not null,
  additionalData   text                    null
)
  engine = MyISAM
    charset = utf8mb3;

create index packageID
  on wcf1_user_notification (packageID);

create table wcf1_user_notification_event
(
  eventID                 int(10) auto_increment
        primary key,
  packageID               int(10)      default 0  not null,
  eventName               varchar(255) default '' not null,
  objectType              varchar(255) default '' not null,
  classFile               varchar(255) default '' not null,
  languageCategory        varchar(255)            not null,
  defaultNotificationType varchar(255)            not null,
  icon                    varchar(255)            not null,
  requiresConfirmation    tinyint(1)   default 0  not null,
  acceptURL               varchar(255) default '' not null,
  declineURL              varchar(255) default '' not null,
  permissions             text                    null,
  options                 text                    null,
  constraint packageID
    unique (packageID, eventName)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_notification_event_to_user
(
  userID           int(10)      default 0  not null,
  packageID        int(10)      default 0  not null,
  objectType       varchar(255) default '' not null,
  eventName        varchar(255) default '' not null,
  notificationType varchar(255) default '' not null,
  enabled          tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create index userID
  on wcf1_user_notification_event_to_user (userID, packageID);

create table wcf1_user_notification_message
(
  messageID        int(10) auto_increment
        primary key,
  notificationID   int(10)      default 0  not null,
  transportID      int(10)      default 0  not null,
  notificationType varchar(255) default '' not null,
  messageCache     text                    null,
  constraint notificationID
    unique (notificationID, notificationType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_notification_object_type
(
  objectTypeID int(10) auto_increment
        primary key,
  packageID    int(10)      not null,
  objectType   varchar(255) not null,
  classFile    varchar(255) not null,
  permissions  text         null,
  options      text         null,
  constraint packageID
    unique (packageID, objectType)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_notification_type
(
  notificationTypeID int(10) auto_increment
        primary key,
  packageID          int(10)      not null,
  notificationType   varchar(255) not null,
  classFile          varchar(255) not null,
  permissions        text         null,
  options            text         null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_option
(
  optionID              int unsigned auto_increment
        primary key,
  packageID             int unsigned        default 0  not null,
  optionName            varchar(255)        default '' not null,
  categoryName          varchar(255)        default '' not null,
  optionType            varchar(255)        default '' not null,
  defaultValue          mediumtext                     null,
  validationPattern     text                           null,
  selectOptions         mediumtext                     null,
  enableOptions         mediumtext                     null,
  required              tinyint(1) unsigned default 0  not null,
  askDuringRegistration tinyint(1) unsigned default 0  not null,
  editable              tinyint(1) unsigned default 0  not null,
  visible               tinyint(1) unsigned default 0  not null,
  outputClass           varchar(255)        default '' not null,
  searchable            tinyint(1) unsigned default 0  not null,
  showOrder             int unsigned        default 0  not null,
  disabled              tinyint(1) unsigned default 0  not null,
  permissions           text                           null,
  options               text                           null,
  additionalData        mediumtext                     null,
  constraint optionName
    unique (optionName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create index categoryName
  on wcf1_user_option (categoryName);

create table wcf1_user_option_category
(
  categoryID         int unsigned auto_increment
        primary key,
  packageID          int unsigned default 0  not null,
  categoryName       varchar(255) default '' not null,
  categoryIconS      varchar(255) default '' not null,
  categoryIconM      varchar(255) default '' not null,
  parentCategoryName varchar(255) default '' not null,
  showOrder          int unsigned default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_option_value
(
  userID       int unsigned        default 0            not null
        primary key,
  userOption1  text                                     null,
  userOption2  tinyint(1) unsigned default 0            not null,
  userOption3  int unsigned        default 0            not null,
  userOption4  text                                     null,
  userOption5  tinyint(1) unsigned default 0            not null,
  userOption6  text                                     null,
  userOption7  char(10)            default '0000-00-00' not null,
  userOption8  text                                     null,
  userOption9  text                                     null,
  userOption10 text                                     null,
  userOption11 text                                     null,
  userOption12 mediumtext                               null,
  userOption13 text                                     null,
  userOption14 text                                     null,
  userOption15 text                                     null,
  userOption16 tinyint(1) unsigned default 0            not null,
  userOption17 tinyint(1) unsigned default 0            not null,
  userOption18 tinyint(1) unsigned default 0            not null,
  userOption19 tinyint(1) unsigned default 0            not null,
  userOption20 tinyint(1) unsigned default 0            not null,
  userOption21 tinyint(1) unsigned default 0            not null,
  userOption22 tinyint(1) unsigned default 0            not null,
  userOption23 tinyint(1) unsigned default 0            not null,
  userOption24 text                                     null,
  userOption25 text                                     null,
  userOption26 text                                     null,
  userOption27 text                                     null,
  userOption28 text                                     null,
  userOption29 text                                     null,
  userOption30 tinyint(1) unsigned default 0            not null,
  userOption31 tinyint(1) unsigned default 0            not null,
  userOption32 tinyint(1) unsigned default 0            not null,
  userOption33 tinyint(1) unsigned default 0            not null,
  userOption34 tinyint(1) unsigned default 0            not null,
  userOption35 tinyint(1) unsigned default 0            not null,
  userOption36 tinyint(1) unsigned default 0            not null,
  userOption37 tinyint(1) unsigned default 0            not null,
  userOption38 tinyint(1) unsigned default 0            not null,
  userOption39 tinyint(1) unsigned default 0            not null,
  userOption40 text                                     null,
  userOption41 tinyint(1) unsigned default 0            not null,
  userOption42 tinyint(1) unsigned default 0            not null,
  userOption43 tinyint(1) unsigned default 0            not null,
  userOption44 tinyint(1) unsigned default 0            not null,
  userOption45 tinyint(1) unsigned default 0            not null,
  userOption46 text                                     null,
  userOption47 text                                     null,
  userOption48 text                                     null,
  userOption50 tinyint(1) unsigned default 0            not null,
  userOption51 tinyint(1) unsigned default 0            not null,
  userOption53 text                                     null,
  userOption56 tinyint(1) unsigned default 0            not null,
  userOption57 tinyint(1) unsigned default 0            not null,
  userOption59 tinyint(1) unsigned default 0            not null,
  userOption60 tinyint(1) unsigned default 0            not null,
  userOption61 tinyint(1) unsigned default 0            not null,
  userOption65 text                                     null,
  userOption66 tinyint(1) unsigned default 0            not null,
  userOption68 text                                     null,
  userOption69 tinyint(1) unsigned default 0            not null,
  userOption70 tinyint(1) unsigned default 0            not null,
  userOption73 tinyint(1) unsigned default 0            not null,
  userOption74 tinyint(1) unsigned default 0            not null,
  userOption75 tinyint(1) unsigned default 0            not null,
  userOption76 tinyint(1) unsigned default 0            not null,
  userOption77 text                                     null,
  userOption78 tinyint(1) unsigned default 0            not null,
  userOption79 int unsigned        default 0            not null,
  userOption80 int unsigned        default 0            not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_profile_menu_item
(
  menuItemID     int unsigned auto_increment
        primary key,
  packageID      int unsigned default 0  not null,
  menuItem       varchar(255) default '' not null,
  parentMenuItem varchar(255) default '' not null,
  menuItemLink   varchar(255) default '' not null,
  menuItemIcon   varchar(255) default '' not null,
  showOrder      int(10)      default 0  not null,
  permissions    text                    null,
  options        text                    null,
  constraint menuItem
    unique (menuItem, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_profile_visitor
(
  ownerID int(10)           not null,
  userID  int(10) default 0 not null,
  time    int(10) default 0 not null,
  constraint ownerID
    unique (ownerID, userID)
)
  engine = MyISAM
    charset = utf8mb3;

create index time
  on wcf1_user_profile_visitor (time);

create table wcf1_user_rank
(
  rankID       int unsigned auto_increment
        primary key,
  groupID      int unsigned default 0  not null,
  neededPoints int unsigned default 0  not null,
  rankTitle    varchar(255) default '' not null,
  rankImage    varchar(255) default '' not null,
  repeatImage  tinyint(3)   default 1  not null,
  gender       tinyint(1)   default 0  not null
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_to_groups
(
  userID  int unsigned default 0 not null,
  groupID int unsigned default 0 not null,
  primary key (userID, groupID)
)
  engine = MyISAM
    charset = utf8mb3;

create index groupID
  on wcf1_user_to_groups (groupID);

create table wcf1_user_to_languages
(
  userID     int unsigned default 0 not null,
  languageID int unsigned default 0 not null,
  primary key (userID, languageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_user_whitelist
(
  userID      int unsigned         not null,
  whiteUserID int unsigned         not null,
  confirmed   tinyint(1) default 0 not null,
  notified    tinyint(1) default 0 not null,
  time        int(10)    default 0 not null,
  constraint userID
    unique (userID, whiteUserID)
)
  engine = MyISAM
    charset = utf8mb3;

create index userID_2
  on wcf1_user_whitelist (userID, confirmed);

create index whiteUserID
  on wcf1_user_whitelist (whiteUserID, confirmed);

create table wcf1_user_wwo
(
  userID           int unsigned not null,
  packageID        int unsigned not null,
  lastActivityTime int unsigned not null,
  primary key (userID, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create index lastActivityTime
  on wcf1_user_wwo (lastActivityTime);

create table wcf1_usercp_menu_item
(
  menuItemID     int unsigned auto_increment
        primary key,
  packageID      int unsigned default 0  not null,
  menuItem       varchar(255) default '' not null,
  parentMenuItem varchar(255) default '' not null,
  menuItemLink   varchar(255) default '' not null,
  menuItemIcon   varchar(255) default '' not null,
  showOrder      int(10)      default 0  not null,
  permissions    text                    null,
  options        text                    null,
  constraint menuItem
    unique (menuItem, packageID)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf1_wqm
(
  wqmID            int unsigned auto_increment
        primary key,
  userID           int unsigned        default 0  not null,
  quotedByUserID   int unsigned        default 0  not null,
  quotedByUsername varchar(255)        default '' not null,
  subject          varchar(255)        default '' not null,
  message          mediumtext                     not null,
  messagePreview   mediumtext                     not null,
  firstID          int unsigned        default 0  not null,
  secondID         int unsigned        default 0  not null,
  thirdID          int unsigned        default 0  not null,
  firstName        varchar(255)        default '' not null,
  secondName       varchar(255)        default '' not null,
  time             int unsigned        default 0  not null,
  type             varchar(255)        default '' not null,
  isViewed         tinyint(1) unsigned default 0  not null,
  isDeleted        tinyint(1) unsigned default 0  not null,
  isNew            tinyint(1) unsigned default 0  not null,
  constraint userID
    unique (userID, quotedByUserID, firstID, secondID, thirdID, type)
)
  engine = MyISAM
    charset = utf8mb3;

create table wcf3_article_search_index
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.woltlab.wcf.article' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on wcf3_article_search_index (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on wcf3_article_search_index (subject);

create index language
  on wcf3_article_search_index (languageID);

create index user
  on wcf3_article_search_index (userID, time);

create table wcf3_background_job
(
  jobID      int(10) auto_increment
        primary key,
  job        mediumblob                                   not null,
  status     enum ('ready', 'processing') default 'ready' not null,
  time       int(10)                                      not null,
  identifier varchar(191)                                 null
)
  collate = utf8mb4_unicode_ci;

create index identifier
  on wcf3_background_job (identifier);

create index status
  on wcf3_background_job (status, time);

create table wcf3_blacklist_entry
(
  type        enum ('email', 'ipv4', 'ipv6', 'username') null,
  hash        binary(32)                                 null,
  lastSeen    datetime                                   not null,
  occurrences smallint(5)                                not null,
  constraint entry
    unique (type, hash)
)
  collate = utf8mb4_unicode_ci;

create index lastSeen
  on wcf3_blacklist_entry (lastSeen);

create index numberOfReports
  on wcf3_blacklist_entry (type, occurrences);

create table wcf3_blacklist_status
(
  date   date                 not null,
  delta1 tinyint(1) default 0 not null,
  delta2 tinyint(1) default 0 not null,
  delta3 tinyint(1) default 0 not null,
  delta4 tinyint(1) default 0 not null,
  constraint day
    unique (date)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_captcha_question
(
  questionID           int(10) auto_increment
        primary key,
  question             varchar(255)         not null,
  answers              mediumtext           null,
  isDisabled           tinyint(1) default 0 not null,
  views                int(10)    default 0 not null,
  correctSubmissions   int(10)    default 0 not null,
  incorrectSubmissions int(10)    default 0 not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_contact_option
(
  optionID          int(10) auto_increment
        primary key,
  optionTitle       varchar(255) default '' not null,
  optionDescription text                    null,
  optionType        varchar(255) default '' not null,
  defaultValue      mediumtext              null,
  validationPattern text                    null,
  selectOptions     mediumtext              null,
  required          tinyint(1)   default 0  not null,
  showOrder         int(10)      default 0  not null,
  isDisabled        tinyint(1)   default 0  not null,
  originIsSystem    tinyint(1)   default 0  not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_contact_recipient
(
  recipientID     int(10) auto_increment
        primary key,
  name            varchar(255)         not null,
  email           varchar(255)         not null,
  showOrder       int(10)    default 0 not null,
  isAdministrator tinyint(1) default 0 not null,
  isDisabled      tinyint(1) default 0 not null,
  originIsSystem  tinyint(1) default 0 not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_conversation_message_search_index
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.woltlab.wcf.conversation.message' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on wcf3_conversation_message_search_index (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on wcf3_conversation_message_search_index (subject);

create index language
  on wcf3_conversation_message_search_index (languageID);

create index user
  on wcf3_conversation_message_search_index (userID, time);

create table wcf3_devtools_project
(
  projectID int(10) auto_increment
        primary key,
  name      varchar(191) not null,
  path      text         null,
  constraint name
    unique (name)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_flood_control
(
  logID        bigint auto_increment
        primary key,
  objectTypeID int(10)    not null,
  identifier   binary(16) not null,
  time         int(10)    not null
)
  collate = utf8mb4_unicode_ci;

create index `0246e06b60efdd5e60b641b5f801149c`
  on wcf3_flood_control (identifier);

create index c15a439049d2db38ab712381d75f7a07
  on wcf3_flood_control (time);

create table wcf3_infraction_warning
(
  warningID int(10) auto_increment
        primary key,
  title     varchar(255) default '' not null,
  points    mediumint(7) default 0  not null,
  expires   int(10)      default 0  not null,
  reason    mediumtext              null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_label_group
(
  groupID          int(10) auto_increment
        primary key,
  groupName        varchar(80)             not null,
  groupDescription varchar(255) default '' not null,
  forceSelection   tinyint(1)   default 0  not null,
  showOrder        int(10)      default 0  not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_label
(
  labelID      int(10) auto_increment
        primary key,
  groupID      int(10)                 not null,
  label        varchar(80)             not null,
  cssClassName varchar(255) default '' not null,
  showOrder    int(10)      default 0  not null,
  constraint e59c7e483a5adfd17e17578d377f89fa_fk
    foreign key (groupID) references wcf3_label_group (groupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_language
(
  languageID   int(10) auto_increment
        primary key,
  languageCode varchar(20)  default '' not null,
  languageName varchar(255) default '' not null,
  countryCode  varchar(10)  default '' not null,
  isDefault    tinyint(1)   default 0  not null,
  hasContent   tinyint(1)   default 0  not null,
  isDisabled   tinyint(1)   default 0  not null,
  locale       varchar(50)  default '' not null,
  constraint languageCode
    unique (languageCode)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_devtools_missing_language_item
(
  itemID       int(10) auto_increment
        primary key,
  languageID   int          null,
  languageItem varchar(191) not null,
  lastTime     int(10)      not null,
  stackTrace   mediumtext   not null,
  constraint `8c94827f62edfe41d034054b8ab1e6a9`
    unique (languageID, languageItem),
  constraint `8c94827f62edfe41d034054b8ab1e6a9_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_language_category
(
  languageCategoryID int(10) auto_increment
        primary key,
  languageCategory   varchar(191) default '' not null,
  constraint languageCategory
    unique (languageCategory)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_notice
(
  noticeID      int(10) auto_increment
        primary key,
  noticeName    varchar(255)                not null,
  notice        mediumtext                  null,
  noticeUseHtml tinyint(1)   default 0      not null,
  cssClassName  varchar(255) default 'info' not null,
  showOrder     int(10)      default 0      not null,
  isDisabled    tinyint(1)   default 0      not null,
  isDismissible tinyint(1)   default 0      not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package
(
  packageID          int(10) auto_increment
        primary key,
  package            varchar(191) default '' not null,
  packageDir         varchar(255) default '' not null,
  packageName        varchar(255) default '' not null,
  packageDescription varchar(255) default '' not null,
  packageVersion     varchar(255) default '' not null,
  packageDate        int(10)      default 0  not null,
  installDate        int(10)      default 0  not null,
  updateDate         int(10)      default 0  not null,
  packageURL         varchar(255) default '' not null,
  isApplication      tinyint(1)   default 0  not null,
  author             varchar(255) default '' not null,
  authorURL          varchar(255) default '' not null,
  constraint package
    unique (package)
)
  collate = utf8mb4_unicode_ci;

create table marketplace3_entry_option
(
  optionID          int(10) auto_increment
        primary key,
  packageID         int(10)                 not null,
  optionName        varchar(191) default '' not null,
  optionDescription text                    null,
  categoryName      varchar(191) default '' not null,
  optionType        varchar(255) default '' not null,
  defaultValue      mediumtext              null,
  validationPattern text                    null,
  selectOptions     mediumtext              null,
  enableOptions     mediumtext              null,
  required          tinyint(1)   default 0  not null,
  editable          tinyint(1)   default 0  not null,
  visible           tinyint(1)   default 0  not null,
  outputClass       varchar(255) default '' not null,
  showOrder         int(10)      default 0  not null,
  isDisabled        tinyint(1)   default 0  not null,
  permissions       text                    null,
  options           text                    null,
  additionalData    mediumtext              null,
  constraint optionName
    unique (optionName),
  constraint `3e3e1cf2b9fe5210867882a457eaa20d_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index categoryName
  on marketplace3_entry_option (categoryName);

create table marketplace3_entry_option_category
(
  categoryID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  categoryName       varchar(191) default '' not null,
  title              varchar(255) default '' not null,
  parentCategoryName varchar(191) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  showInSidebar      tinyint(1)   default 0  not null,
  constraint categoryName
    unique (categoryName),
  constraint `5ff87397d0d06e9f97f157646c65be0c_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acp_menu_item
(
  menuItemID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  menuItem           varchar(191) default '' not null,
  parentMenuItem     varchar(191) default '' not null,
  menuItemController varchar(255) default '' not null,
  menuItemLink       varchar(255) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  icon               varchar(255) default '' not null,
  constraint menuItem
    unique (menuItem, packageID),
  constraint a6079a6caeeb97a32e56a3543622926f_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acp_search_provider
(
  providerID   int(10) auto_increment
        primary key,
  packageID    int(10)                 not null,
  providerName varchar(191) default '' not null,
  className    varchar(255) default '' not null,
  showOrder    int(10)      default 0  not null,
  constraint providerName
    unique (providerName, packageID),
  constraint `5394179e1ee6a586561aa0df0a91dbfa_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acp_template
(
  templateID   int(10) auto_increment
        primary key,
  packageID    int(10)      not null,
  templateName varchar(191) not null,
  application  varchar(20)  not null,
  constraint applicationTemplate
    unique (application, templateName),
  constraint `6a12528131e0bf98dc6ab4136faa9791_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_bbcode
(
  bbcodeID       int(10) auto_increment
        primary key,
  bbcodeTag      varchar(191)            not null,
  packageID      int(10)                 not null,
  htmlOpen       varchar(255) default '' not null,
  htmlClose      varchar(255) default '' not null,
  className      varchar(255) default '' not null,
  wysiwygIcon    varchar(255) default '' not null,
  buttonLabel    varchar(255) default '' not null,
  isBlockElement tinyint(1)   default 0  not null,
  isSourceCode   tinyint(1)   default 0  not null,
  showButton     tinyint(1)   default 0  not null,
  originIsSystem tinyint(1)   default 0  not null,
  constraint bbcodeTag
    unique (bbcodeTag),
  constraint `8f18deb4ecab534ac1f94df3c39913e0_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_bbcode_attribute
(
  attributeID       int(10) auto_increment
        primary key,
  bbcodeID          int(10)                 not null,
  attributeNo       tinyint(3)   default 0  not null,
  attributeHtml     varchar(255) default '' not null,
  validationPattern varchar(255) default '' not null,
  required          tinyint(1)   default 0  not null,
  useText           tinyint(1)   default 0  not null,
  constraint attributeNo
    unique (bbcodeID, attributeNo),
  constraint `296556aae14c07312aea40aa9956bec6_fk`
    foreign key (bbcodeID) references wcf3_bbcode (bbcodeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_bbcode_media_provider
(
  providerID int(10) auto_increment
        primary key,
  title      varchar(255)            not null,
  regex      text                    not null,
  html       text                    not null,
  name       varchar(80)             not null,
  packageID  int(10)                 not null,
  className  varchar(255) default '' not null,
  isDisabled tinyint(1)   default 0  not null,
  constraint name
    unique (name, packageID),
  constraint `69bd05cb30fd9f79b0729c33014b7adb_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_clipboard_action
(
  actionID        int(10) auto_increment
        primary key,
  packageID       int(10)      default 0  not null,
  actionName      varchar(50)  default '' not null,
  actionClassName varchar(191) default '' not null,
  showOrder       int(10)      default 0  not null,
  constraint actionName
    unique (packageID, actionName, actionClassName),
  constraint cd9383a6cf6a59cd932aa049f9bbdc1a_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_clipboard_page
(
  pageClassName varchar(80) default '' not null,
  packageID     int(10)     default 0  not null,
  actionID      int(10)     default 0  not null,
  constraint `661c578c5781d7d048f37ab748bbf2d9_fk`
    foreign key (actionID) references wcf3_clipboard_action (actionID)
      on delete cascade,
  constraint f753eada56a20da64e82b2ad119671d1_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_core_object
(
  objectID   int(10) auto_increment
        primary key,
  packageID  int(10)                 not null,
  objectName varchar(191) default '' not null,
  constraint object
    unique (packageID, objectName),
  constraint `5c6b23a90ae940534ab27954c82f4973_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_cronjob
(
  cronjobID     int(10) auto_increment
        primary key,
  className     varchar(255) default ''  not null,
  packageID     int(10)                  not null,
  cronjobName   varchar(191)             not null,
  description   varchar(255) default ''  not null,
  startMinute   varchar(255) default '*' not null,
  startHour     varchar(255) default '*' not null,
  startDom      varchar(255) default '*' not null,
  startMonth    varchar(255) default '*' not null,
  startDow      varchar(255) default '*' not null,
  lastExec      int(10)      default 0   not null,
  nextExec      int(10)      default 0   not null,
  afterNextExec int(10)      default 0   not null,
  isDisabled    tinyint(1)   default 0   not null,
  canBeEdited   tinyint(1)   default 1   not null,
  canBeDisabled tinyint(1)   default 1   not null,
  state         tinyint(1)   default 0   not null,
  failCount     tinyint(1)   default 0   not null,
  options       text                     null,
  constraint cronjobName
    unique (cronjobName, packageID),
  constraint `1400d510fd0b5cb81d0924b57caa9b2c_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_cronjob_log
(
  cronjobLogID int(10) auto_increment
        primary key,
  cronjobID    int(10)              not null,
  execTime     int(10)    default 0 not null,
  success      tinyint(1) default 0 not null,
  error        text                 null,
  constraint d15412f3a49f9b33feb07844484eea05_fk
    foreign key (cronjobID) references wcf3_cronjob (cronjobID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_event_listener
(
  listenerID        int(10) auto_increment
        primary key,
  packageID         int(10)                       not null,
  environment       enum ('user', 'admin', 'all') null,
  listenerName      varchar(191)                  not null,
  eventClassName    varchar(255) default ''       not null,
  eventName         text                          null,
  listenerClassName varchar(200) default ''       not null,
  inherit           tinyint(1)   default 0        not null,
  niceValue         tinyint(3)   default 0        not null,
  permissions       text                          null,
  options           text                          null,
  constraint listenerName
    unique (listenerName, packageID),
  constraint `3f4b113c844445cd048d32ffa177b86b_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_language_item
(
  languageItemID                int(10) auto_increment
        primary key,
  languageID                    int(10)                 not null,
  languageItem                  varchar(191) default '' not null,
  languageItemValue             mediumtext              not null,
  languageCustomItemValue       mediumtext              null,
  languageUseCustomValue        tinyint(1)   default 0  not null,
  languageItemOriginIsSystem    tinyint(1)   default 1  not null,
  languageCategoryID            int(10)                 not null,
  packageID                     int(10)                 not null,
  languageItemOldValue          mediumtext              null,
  languageCustomItemDisableTime int(10)                 null,
  isCustomLanguageItem          tinyint(1)   default 0  not null,
  constraint languageItem
    unique (languageItem, languageID),
  constraint `311d6a6aa98417e5cd780954dbc10c58_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint d15480ccb65f046c8a1a2709a3c3d319_fk
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade,
  constraint db1f4dbf3a1d5a41f118b79847a88d69_fk
    foreign key (languageCategoryID) references wcf3_language_category (languageCategoryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index languageItemOriginIsSystem
  on wcf3_language_item (languageItemOriginIsSystem);

create table wcf3_menu
(
  menuID         int(10) auto_increment
        primary key,
  identifier     varchar(255)         not null,
  title          varchar(255)         not null,
  originIsSystem tinyint(1) default 0 not null,
  packageID      int(10)              not null,
  constraint `64d3ba603d140d0d09704477d43855a6_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_oauth_scope
(
  scopeID      int(10) auto_increment
        primary key,
  scope        varchar(80)          not null,
  isDefault    tinyint(1) default 0 not null,
  packageID    int(10)              not null,
  showOrder    int(5)     default 0 null,
  categoryName varchar(181)         not null,
  constraint scope
    unique (scope),
  constraint `684f46489a7e69535e285bb9b25e9bea_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index categoryName
  on wcf3_oauth_scope (categoryName);

create index showOrder
  on wcf3_oauth_scope (showOrder);

create table wcf3_oauth_scope_category
(
  categoryID   int(10) auto_increment
        primary key,
  categoryName varchar(181) not null,
  packageID    int(10)      not null,
  icon         varchar(50)  null,
  showOrder    int(5)       not null,
  constraint categoryName
    unique (categoryName),
  constraint `5961b303a6bdc759161f903b0e6da1ba_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index showOrder
  on wcf3_oauth_scope_category (showOrder);

create table wcf3_object_type_definition
(
  definitionID   int(10) auto_increment
        primary key,
  definitionName varchar(191)            not null,
  packageID      int(10)                 not null,
  interfaceName  varchar(255) default '' not null,
  categoryName   varchar(80)  default '' not null,
  constraint definitionName
    unique (definitionName),
  constraint f60301e9e112434474395d9dd2a371d7_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_object_type
(
  objectTypeID   int(10) auto_increment
        primary key,
  definitionID   int(10)                 not null,
  packageID      int(10)                 not null,
  objectType     varchar(191)            not null,
  className      varchar(255) default '' not null,
  additionalData mediumtext              null,
  constraint objectType
    unique (objectType, definitionID, packageID),
  constraint `51760285281a69840fd71a3dc1556244_fk`
    foreign key (definitionID) references wcf3_object_type_definition (definitionID)
      on delete cascade,
  constraint f9e30956fbfad9ab033b435ae213b648_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table marketplace3_rating_category
(
  ratingCategoryID int(10) auto_increment
        primary key,
  name             varchar(255) default ''             not null,
  description      text                                not null,
  type             enum ('buyer', 'seller', 'partner') not null,
  isActive         tinyint(1)   default 1              not null,
  objectTypeID     int(10)                             not null,
  isFinalRating    tinyint(1)   default 1              not null,
  showOrder        int(5)       default 0              not null,
  constraint b069f2d8e11695a748ebdf3e19fcb0ea_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index isActive
  on marketplace3_rating_category (isActive);

create index ratingObjectTypeID
  on marketplace3_rating_category (objectTypeID);

create index showOrder
  on marketplace3_rating_category (showOrder);

create index type
  on marketplace3_rating_category (type);

create table wcf3_acl_option
(
  optionID     int(10) auto_increment
        primary key,
  packageID    int(10)      not null,
  objectTypeID int(10)      not null,
  optionName   varchar(191) not null,
  categoryName varchar(191) not null,
  constraint packageID
    unique (packageID, objectTypeID, optionName),
  constraint `5ef038bd3663501ba30b43995c5ec56e_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint `8cfaaa9fc18a01bb6e0b1a22461e2e2b_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acl_option_category
(
  categoryID   int(10) auto_increment
        primary key,
  packageID    int(10)      not null,
  objectTypeID int(10)      not null,
  categoryName varchar(191) not null,
  constraint packageID
    unique (packageID, objectTypeID, categoryName),
  constraint f4b441de1fce1bdd63bda6117a274a87_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint f78eb3c544014a6f008f53391aae2ab5_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_ad
(
  adID         int(10) auto_increment
        primary key,
  objectTypeID int(10)              not null,
  adName       varchar(255)         not null,
  ad           mediumtext           null,
  isDisabled   tinyint(1) default 0 not null,
  showOrder    int(10)    default 0 not null,
  constraint `00c47417f8e4ced6d059388dc47373c8_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_category
(
  categoryID         int(10) auto_increment
        primary key,
  objectTypeID       int(10)              not null,
  parentCategoryID   int(10)    default 0 not null,
  title              varchar(255)         not null,
  description        text                 null,
  showOrder          int(10)    default 0 not null,
  time               int(10)    default 0 not null,
  isDisabled         tinyint(1) default 0 not null,
  additionalData     text                 null,
  descriptionUseHtml tinyint(1) default 0 not null,
  constraint `211855ba4c454c7f3e5992eb569e9ad2_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_clipboard_item
(
  objectTypeID int(10) default 0 not null,
  userID       int(10) default 0 not null,
  objectID     int(10) default 0 not null,
  constraint objectTypeID
    unique (objectTypeID, userID, objectID),
  constraint a0690b0b2f7b82ffccc60c9260ca8148_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index userID
  on wcf3_clipboard_item (userID);

create table wcf3_condition
(
  conditionID   int(10) auto_increment
        primary key,
  objectTypeID  int(10)    not null,
  objectID      int(10)    not null,
  conditionData mediumtext null,
  constraint e1387dd3866c91fcd19a2f02a82ba123_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_file
(
  fileID        int(10) auto_increment
        primary key,
  filename      varchar(255) not null,
  fileSize      bigint       not null,
  fileHash      char(64)     not null,
  fileExtension varchar(10)  not null,
  objectTypeID  int          null,
  mimeType      varchar(255) not null,
  width         int          null,
  height        int          null,
  fileHashWebp  char(64)     null,
  constraint `64c82be7e8a5db684bcf46d2c5170eb9_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete set null
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_file_temporary
(
  identifier   char(40)       not null
    primary key,
  time         int(10)        not null,
  filename     varchar(255)   not null,
  fileSize     bigint         not null,
  fileHash     char(64)       not null,
  objectTypeID int            null,
  context      text           null,
  chunks       varbinary(255) not null,
  constraint `101c333c84ba268b06cc29078a580f05_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete set null
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_file_thumbnail
(
  thumbnailID    int(10) auto_increment
        primary key,
  fileID         int(10)     not null,
  identifier     varchar(50) not null,
  fileHash       char(64)    not null,
  fileExtension  varchar(10) not null,
  width          int         not null,
  height         int         not null,
  formatChecksum char(12)    null,
  constraint `457a2760a011d5f15fe7118709685ea7_fk`
    foreign key (fileID) references wcf3_file (fileID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_import_mapping
(
  importHash   char(8)      not null,
  objectTypeID int(10)      not null,
  oldID        varchar(191) not null,
  newID        int(10)      not null,
  constraint importHash
    unique (importHash, objectTypeID, oldID),
  constraint `0eb5d30a447fd4c5cbf1164e7fe43fc8_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_infraction_suspension
(
  suspensionID   int(10) auto_increment
        primary key,
  title          varchar(255) default '' not null,
  points         mediumint(7) default 0  not null,
  expires        int(10)      default 0  not null,
  objectTypeID   int(10)                 not null,
  suspensionData mediumtext              null,
  constraint `928e7b50ced63fe2ba2bdb74381ca85f_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID
  on wcf3_infraction_suspension (objectTypeID);

create table wcf3_label_group_to_object
(
  groupID      int(10) not null,
  objectTypeID int(10) not null,
  objectID     int(10) null,
  constraint `1ed4710a5bcbc605cd16358255bf8510_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint db686d56ad7d140bef1e5d1280e1fd6e_fk
    foreign key (groupID) references wcf3_label_group (groupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_label_object
(
  labelID      int(10) not null,
  objectTypeID int(10) not null,
  objectID     int(10) not null,
  constraint `91f5dc0ac99e1f44e7a828a38068647f_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint d2c7510cec17a1701a3ffefefe8eabc8_fk
    foreign key (labelID) references wcf3_label (labelID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID
  on wcf3_label_object (objectTypeID, labelID);

create index objectTypeID_2
  on wcf3_label_object (objectTypeID, objectID);

create table wcf3_message_embedded_object
(
  messageObjectTypeID  int(10) not null,
  messageID            int(10) not null,
  embeddedObjectTypeID int(10) not null,
  embeddedObjectID     int(10) not null,
  constraint messageEmbeddedObject
    unique (messageObjectTypeID, messageID, embeddedObjectTypeID, embeddedObjectID),
  constraint `4730702ea2d9580e2a7587cdc1db63a9_fk`
    foreign key (embeddedObjectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint a24f6eb1b99764138225ca242f80a2aa_fk
    foreign key (messageObjectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index messageObjectTypeID
  on wcf3_message_embedded_object (messageObjectTypeID, messageID);

create table wcf3_option
(
  optionID          int(10) auto_increment
        primary key,
  packageID         int(10)                 not null,
  optionName        varchar(191) default '' not null,
  categoryName      varchar(191) default '' not null,
  optionType        varchar(255) default '' not null,
  optionValue       mediumtext              null,
  validationPattern text                    null,
  selectOptions     mediumtext              null,
  enableOptions     mediumtext              null,
  showOrder         int(10)      default 0  not null,
  hidden            tinyint(1)   default 0  not null,
  permissions       text                    null,
  options           text                    null,
  supportI18n       tinyint(1)   default 0  not null,
  requireI18n       tinyint(1)   default 0  not null,
  additionalData    mediumtext              null,
  constraint optionName
    unique (optionName),
  constraint `22073ef740fd1f29ce4e559cc2eb6e8a_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_option_category
(
  categoryID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  categoryName       varchar(191) default '' not null,
  parentCategoryName varchar(191) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName),
  constraint `0b2b7080a54c1aff8bcb41786776f9df_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_audit_log
(
  logID      bigint auto_increment
        primary key,
  payload    mediumtext   not null,
  time       varchar(255) not null,
  wcfVersion varchar(255) not null,
  requestId  varchar(255) not null
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_package_exclusion
(
  packageID              int(10)                 not null,
  excludedPackage        varchar(191) default '' not null,
  excludedPackageVersion varchar(255) default '' not null,
  constraint packageID
    unique (packageID, excludedPackage),
  constraint dd1444ed7fdd8d28c6e2a17b01c06d60_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_installation_file_log
(
  packageID   int(10)        not null,
  filename    varbinary(765) not null,
  application varchar(20)    not null,
  sha256      varbinary(32)  null,
  lastUpdated bigint         null,
  constraint applicationFile
    unique (application, filename),
  constraint `64209fabde76639f742e4c6042cb9d2a_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_installation_plugin
(
  pluginName varchar(191)         not null
    primary key,
  packageID  int(10)              not null,
  priority   tinyint(1) default 0 not null,
  className  varchar(255)         not null,
  constraint af2243cb7c0e5d7f1ff573a9ceba6d3c_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_installation_sql_log
(
  packageID int(10)                 not null,
  sqlTable  varchar(100) default '' not null,
  sqlColumn varchar(100) default '' not null,
  sqlIndex  varchar(100) default '' not null,
  isDone    tinyint(1)   default 1  not null,
  constraint packageID
    unique (packageID, sqlTable, sqlColumn, sqlIndex),
  constraint c8e6d66d9f54aa3e6e81a632112e0e9d_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_requirement
(
  packageID   int(10) not null,
  requirement int(10) not null,
  constraint packageID
    unique (packageID, requirement),
  constraint `2798d939f822fdab9028b3afa3fcc663_fk`
    foreign key (requirement) references wcf3_package (packageID)
      on delete cascade,
  constraint `85b7de0def2f651a5f156d9c946e4223_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update_server
(
  packageUpdateServerID int(10) auto_increment
        primary key,
  serverURL             varchar(255)               default ''       not null,
  loginUsername         varchar(255)               default ''       not null,
  loginPassword         varchar(255)               default ''       not null,
  isDisabled            tinyint(1)                 default 0        not null,
  lastUpdateTime        int(10)                    default 0        not null,
  status                enum ('online', 'offline') default 'online' not null,
  errorMessage          text                                        null,
  apiVersion            enum ('2.0', '2.1', '3.1') default '2.0'    not null,
  metaData              text                                        null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update
(
  packageUpdateID       int(10) auto_increment
        primary key,
  packageUpdateServerID int(10)                 not null,
  package               varchar(191) default '' not null,
  packageName           varchar(255) default '' not null,
  packageDescription    varchar(255) default '' not null,
  author                varchar(255) default '' not null,
  authorURL             varchar(255) default '' not null,
  isApplication         tinyint(1)   default 0  not null,
  pluginStoreFileID     int(10)      default 0  not null,
  constraint packageUpdateServerID
    unique (packageUpdateServerID, package),
  constraint f84945c4ade151f302d7e1c4403e1877_fk
    foreign key (packageUpdateServerID) references wcf3_package_update_server (packageUpdateServerID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update_version
(
  packageUpdateVersionID int(10) auto_increment
        primary key,
  packageUpdateID        int(10)                 not null,
  packageVersion         varchar(50)  default '' not null,
  packageDate            int(10)      default 0  not null,
  filename               varchar(255) default '' not null,
  license                varchar(255) default '' not null,
  licenseURL             varchar(255) default '' not null,
  isAccessible           tinyint(1)   default 1  not null,
  constraint packageUpdateID
    unique (packageUpdateID, packageVersion),
  constraint `0f9dff841d0325f3576a4def8109a596_fk`
    foreign key (packageUpdateID) references wcf3_package_update (packageUpdateID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update_exclusion
(
  packageUpdateVersionID int(10)                 not null,
  excludedPackage        varchar(191) default '' not null,
  excludedPackageVersion varchar(255) default '' not null,
  constraint packageUpdateVersionID
    unique (packageUpdateVersionID, excludedPackage),
  constraint b6a74fabb76107cc559a7d7cab2d6ad0_fk
    foreign key (packageUpdateVersionID) references wcf3_package_update_version (packageUpdateVersionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update_fromversion
(
  packageUpdateVersionID int(10)     default 0  not null,
  fromversion            varchar(50) default '' not null,
  constraint packageUpdateVersionID
    unique (packageUpdateVersionID, fromversion),
  constraint `43be7ac4fa7838277b212a5341f8007b_fk`
    foreign key (packageUpdateVersionID) references wcf3_package_update_version (packageUpdateVersionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_update_requirement
(
  packageUpdateVersionID int(10)                 not null,
  package                varchar(191) default '' not null,
  minversion             varchar(50)  default '' not null,
  constraint packageUpdateVersionID
    unique (packageUpdateVersionID, package),
  constraint `08f4e374196cd959046eb4d6ddf2c786_fk`
    foreign key (packageUpdateVersionID) references wcf3_package_update_version (packageUpdateVersionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_page
(
  pageID                       int(10) auto_increment
        primary key,
  parentPageID                 int(10)                 null,
  identifier                   varchar(255)            not null,
  name                         varchar(255)            not null,
  pageType                     varchar(255)            not null,
  isDisabled                   tinyint(1)   default 0  not null,
  isMultilingual               tinyint(1)   default 0  not null,
  originIsSystem               tinyint(1)   default 0  not null,
  packageID                    int(10)                 not null,
  applicationPackageID         int(10)                 null,
  controller                   varchar(255) default '' not null,
  handler                      varchar(255) default '' not null,
  controllerCustomURL          varchar(255) default '' not null,
  requireObjectID              tinyint(1)   default 0  not null,
  hasFixedParent               tinyint(1)   default 0  not null,
  lastUpdateTime               int(10)      default 0  not null,
  permissions                  text                    null,
  options                      text                    null,
  cssClassName                 varchar(255) default '' not null,
  availableDuringOfflineMode   tinyint(1)   default 0  not null,
  allowSpidersToIndex          tinyint(1)   default 0  not null,
  excludeFromLandingPage       tinyint(1)   default 0  not null,
  overrideApplicationPackageID int(10)                 null,
  enableShareButtons           tinyint(1)   default 0  not null,
  invertPermissions            tinyint(1)   default 0  not null,
  constraint `1fde8c3d3e9aa3d2bb8501dfd94a2ee0_fk`
    foreign key (applicationPackageID) references wcf3_package (packageID)
      on delete set null,
  constraint `35c3ac1f97df0ded7389c3538ba138e2_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint `74c4e186a2dc45da22398e7f2563dcf0_fk`
    foreign key (parentPageID) references wcf3_page (pageID)
      on delete set null,
  constraint aa0651eb22f20b987c5354062eb4312f_fk
    foreign key (overrideApplicationPackageID) references wcf3_package (packageID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_application
(
  packageID     int(10)                  not null
        primary key,
  domainName    varchar(255)             not null,
  domainPath    varchar(255) default '/' not null,
  cookieDomain  varchar(255)             not null,
  isTainted     tinyint(1)   default 0   not null,
  landingPageID int(10)                  null,
  constraint `5297e762115cf706ae1b1b306261ad70_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint `75c37e239ac17893957bff9368a9229f_fk`
    foreign key (landingPageID) references wcf3_page (pageID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_box
(
  boxID             int(10) auto_increment
        primary key,
  objectTypeID      int(10)                 null,
  identifier        varchar(255)            not null,
  name              varchar(255)            not null,
  boxType           varchar(255)            not null,
  position          varchar(255)            not null,
  showOrder         int(10)      default 0  not null,
  visibleEverywhere tinyint(1)   default 1  not null,
  isMultilingual    tinyint(1)   default 0  not null,
  cssClassName      varchar(255) default '' not null,
  showHeader        tinyint(1)   default 1  not null,
  originIsSystem    tinyint(1)   default 0  not null,
  packageID         int(10)                 not null,
  menuID            int(10)                 null,
  linkPageID        int(10)                 null,
  linkPageObjectID  int(10)      default 0  not null,
  externalURL       varchar(255) default '' not null,
  additionalData    text                    null,
  lastUpdateTime    int(10)      default 0  not null,
  isDisabled        tinyint(1)   default 0  not null,
  invertPermissions tinyint(1)   default 0  not null,
  constraint `7ce4e7e5cd34ac3a495ccf92b0dd8faf_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint `9e071711d9b00330ccad9a4a8434af74_fk`
    foreign key (linkPageID) references wcf3_page (pageID)
      on delete set null,
  constraint e752bf94829283baa90837795e481db0_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint fd9e5dcfd21f13ad1cb366e4c5277ce4_fk
    foreign key (menuID) references wcf3_menu (menuID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_box_to_page
(
  boxID   int(10)              not null,
  pageID  int(10)              not null,
  visible tinyint(1) default 1 not null,
  constraint pageID
    unique (pageID, boxID),
  constraint bdfd9cce1861b9b5bc81ed10795196fd_fk
    foreign key (pageID) references wcf3_page (pageID)
      on delete cascade,
  constraint e3ed70b0e6aa8cc217515d2a5e6431fd_fk
    foreign key (boxID) references wcf3_box (boxID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index pageID_2
  on wcf3_box_to_page (pageID, visible);

create table wcf3_menu_item
(
  itemID         int(10) auto_increment
        primary key,
  menuID         int(10)                 not null,
  parentItemID   int(10)                 null,
  identifier     varchar(255)            not null,
  title          varchar(255)            not null,
  pageID         int(10)                 null,
  pageObjectID   int(10)      default 0  not null,
  externalURL    varchar(255) default '' not null,
  showOrder      int(10)      default 0  not null,
  isDisabled     tinyint(1)   default 0  not null,
  originIsSystem tinyint(1)   default 0  not null,
  packageID      int(10)                 not null,
  constraint `231b7464362053c80591a7000715f440_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint bade758e58080b7f34350b242f2ebaef_fk
    foreign key (menuID) references wcf3_menu (menuID)
      on delete cascade,
  constraint c67772b3cb56405b20f35bcd067c1103_fk
    foreign key (pageID) references wcf3_page (pageID)
      on delete cascade,
  constraint d1f39f4c7dc5a2c073e9eb747ed0a83f_fk
    foreign key (parentItemID) references wcf3_menu_item (itemID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_page_box_order
(
  pageID    int(10)           not null,
  boxID     int(10)           not null,
  showOrder int(10) default 0 not null,
  constraint pageToBox
    unique (pageID, boxID),
  constraint `5b441e4f8a13cf25405fd787715f7f7e_fk`
    foreign key (boxID) references wcf3_box (boxID)
      on delete cascade,
  constraint `8165609ab1db9f7e86bc6d39a69a5938_fk`
    foreign key (pageID) references wcf3_page (pageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_page_content
(
  pageContentID      int(10) auto_increment
        primary key,
  pageID             int(10)              not null,
  languageID         int(10)              null,
  title              varchar(255)         not null,
  content            mediumtext           null,
  metaDescription    text                 null,
  customURL          varchar(255)         not null,
  hasEmbeddedObjects tinyint(1) default 0 not null,
  constraint pageID
    unique (pageID, languageID),
  constraint `0f357d2cab6cf06066903f64458b776e_fk`
    foreign key (pageID) references wcf3_page (pageID)
      on delete cascade,
  constraint `56e1b3e6804d8df75ad95841f12c958e_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_page_search_index
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.woltlab.wcf.page' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on wcf3_page_search_index (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on wcf3_page_search_index (subject);

create index language
  on wcf3_page_search_index (languageID);

create index user
  on wcf3_page_search_index (userID, time);

create table wcf3_paid_subscription
(
  subscriptionID          int(10) auto_increment
        primary key,
  title                   varchar(255)             default ''    not null,
  description             text                                   null,
  isDisabled              tinyint(1)               default 0     not null,
  showOrder               int(10)                  default 0     not null,
  cost                    decimal(10, 2)           default 0.00  not null,
  currency                varchar(3)               default 'EUR' not null,
  subscriptionLength      smallint(3)              default 0     not null,
  subscriptionLengthUnit  enum ('', 'D', 'M', 'Y') default ''    not null,
  isRecurring             tinyint(1)               default 0     not null,
  groupIDs                text                                   null,
  excludedSubscriptionIDs text                                   null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_poll
(
  pollID             int(10) auto_increment
        primary key,
  objectTypeID       int(10)                 not null,
  objectID           int(10)      default 0  not null,
  question           varchar(255) default '' null,
  time               int(10)      default 0  not null,
  endTime            int(10)      default 0  not null,
  isChangeable       tinyint(1)   default 0  not null,
  isPublic           tinyint(1)   default 0  not null,
  sortByVotes        tinyint(1)   default 0  not null,
  resultsRequireVote tinyint(1)   default 0  not null,
  maxVotes           int(10)      default 1  not null,
  votes              int(10)      default 0  not null,
  constraint fa02be88d8cd0aa75dd3e006e7ce2750_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_poll_option
(
  optionID    int(10) auto_increment
        primary key,
  pollID      int(10)                 not null,
  optionValue varchar(255) default '' not null,
  votes       int(10)      default 0  not null,
  showOrder   int(10)      default 0  not null,
  constraint `250e4a1c6dc35db964fe97edf9a03f14_fk`
    foreign key (pollID) references wcf3_poll (pollID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_reaction_type
(
  reactionTypeID int(10) auto_increment
        primary key,
  title          varchar(255)            not null,
  showOrder      int(10)      default 0  not null,
  iconFile       varchar(255) default '' not null,
  isAssignable   tinyint(1)   default 1  not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_registry
(
  packageID  int(10)      not null,
  field      varchar(191) not null,
  fieldValue mediumtext   null,
  constraint uniqueField
    unique (packageID, field),
  constraint `84e54d6596e972eb29df756236536ad0_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_search_index_5c741453
(
  objectID   int(10)           not null,
  subject    varchar(255)      not null,
  message    mediumtext        null,
  metaData   mediumtext        null,
  time       int(10) default 0 not null,
  userID     int(10)           null,
  username   varchar(255)      not null,
  languageID int(10) default 0 not null,
  constraint objectAndLanguage
    unique (objectID, languageID)
)
comment 'Search index for com.viecode.marketplace.entry' collate = utf8mb4_unicode_ci;

create fulltext index fulltextIndex
    on wcf3_search_index_5c741453 (subject, message, metaData);

create fulltext index fulltextIndexSubjectOnly
    on wcf3_search_index_5c741453 (subject);

create index language
  on wcf3_search_index_5c741453 (languageID);

create index user
  on wcf3_search_index_5c741453 (userID, time);

create table wcf3_search_keyword
(
  keywordID      int(10) auto_increment
        primary key,
  keyword        varchar(191)      not null,
  searches       int(10) default 0 not null,
  lastSearchTime int(10) default 0 not null,
  constraint keyword
    unique (keyword)
)
  collate = utf8mb4_unicode_ci;

create index searches
  on wcf3_search_keyword (searches, lastSearchTime);

create table wcf3_smiley
(
  smileyID     int(10) auto_increment
        primary key,
  packageID    int(10)                 not null,
  categoryID   int(10)                 null,
  smileyPath   varchar(255) default '' not null,
  smileyPath2x varchar(255) default '' not null,
  smileyTitle  varchar(255) default '' not null,
  smileyCode   varchar(191) default '' not null,
  aliases      text                    not null,
  showOrder    int(10)      default 0  not null,
  constraint smileyCode
    unique (smileyCode),
  constraint ca7b132d8dd6676923202cceac7f896e_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint e16697dbee3c335d114869eb2c987020_fk
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_stat_daily
(
  statID       int(10) auto_increment
        primary key,
  objectTypeID int(10)           not null,
  date         date              not null,
  counter      int(10) default 0 not null,
  total        int(10) default 0 not null,
  constraint objectTypeID
    unique (objectTypeID, date),
  constraint db8c40f7f69eef673357aaba9e176ecd_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_style
(
  styleID             int(10) auto_increment
        primary key,
  packageID           int(10)                           not null,
  styleName           varchar(255) default ''           not null,
  templateGroupID     int(10)      default 0            not null,
  isDefault           tinyint(1)   default 0            not null,
  isDisabled          tinyint(1)   default 0            not null,
  styleDescription    varchar(30)  default ''           not null,
  styleVersion        varchar(255) default ''           not null,
  styleDate           char(10)     default '0000-00-00' not null,
  image               varchar(255) default ''           not null,
  copyright           varchar(255) default ''           not null,
  license             varchar(255) default ''           not null,
  authorName          varchar(255) default ''           not null,
  authorURL           varchar(255) default ''           not null,
  imagePath           varchar(255) default ''           not null,
  packageName         varchar(255) default ''           not null,
  isTainted           tinyint(1)   default 0            not null,
  image2x             varchar(255) default ''           not null,
  hasFavicon          tinyint(1)   default 0            not null,
  coverPhotoExtension varchar(4)   default ''           not null,
  hasDarkMode         tinyint(1)   default 0            not null,
  constraint `805ded422e8719653776b44bb2eacd51_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_board
(
  boardID                     int(10) auto_increment
        primary key,
  parentID                    int(10)                 null,
  position                    smallint(5)  default 0  not null,
  boardType                   tinyint(1)   default 0  not null,
  title                       varchar(255) default '' not null,
  description                 mediumtext              not null,
  descriptionUseHtml          tinyint(1)   default 0  not null,
  externalURL                 varchar(255) default '' not null,
  time                        int(10)      default 0  not null,
  countUserPosts              tinyint(1)   default 1  not null,
  daysPrune                   smallint(5)  default 0  not null,
  enableMarkingAsDone         tinyint(1)   default 0  not null,
  ignorable                   tinyint(1)   default 1  not null,
  isClosed                    tinyint(1)   default 0  not null,
  isInvisible                 tinyint(1)   default 0  not null,
  postsPerPage                smallint(5)  default 0  not null,
  searchable                  tinyint(1)   default 1  not null,
  searchableForSimilarThreads tinyint(1)   default 1  not null,
  sortField                   varchar(20)  default '' not null,
  sortOrder                   varchar(4)   default '' not null,
  styleID                     int(10)                 null,
  threadsPerPage              smallint(5)  default 0  not null,
  clicks                      int(10)      default 0  not null,
  posts                       int(10)      default 0  not null,
  threads                     int(10)      default 0  not null,
  isPrivate                   tinyint(1)   default 0  not null,
  iconData                    text                    null,
  metaDescription             varchar(255) default '' not null,
  enableBestAnswer            tinyint(1)   default 0  not null,
  formID                      int                     null,
  constraint parentID
    unique (parentID, boardID),
  constraint `1cca5441ca1ff13277cb0eeb87990945_fk`
    foreign key (styleID) references wcf3_style (styleID)
      on delete set null,
  constraint `4767330cc0a5327204567c07c9815414_fk`
    foreign key (parentID) references wbb3_board (boardID)
      on delete set null,
  constraint `7b9ff1638e92ebc0c4fe94e638b5ce2d_fk`
    foreign key (formID) references wbb3_thread_form (formID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_style_variable
(
  variableID           int(10) auto_increment
        primary key,
  variableName         varchar(50) not null,
  defaultValue         mediumtext  null,
  defaultValueDarkMode mediumtext  null,
  constraint variableName
    unique (variableName)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_style_variable_value
(
  styleID               int(10)    not null,
  variableID            int(10)    not null,
  variableValue         mediumtext null,
  variableValueDarkMode mediumtext null,
  constraint styleID
    unique (styleID, variableID),
  constraint `54e4307d7a1780fc1a85097e619d0dfe_fk`
    foreign key (styleID) references wcf3_style (styleID)
      on delete cascade,
  constraint c839dafd6acddb61f10bbba834acbd15_fk
    foreign key (variableID) references wcf3_style_variable (variableID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_tag
(
  tagID      int(10) auto_increment
        primary key,
  languageID int(10) default 0 not null,
  name       varchar(191)      not null,
  synonymFor int(10)           null,
  constraint languageID
    unique (languageID, name),
  constraint `5ca1994226a2c8ce47c3df44d9442e90_fk`
    foreign key (synonymFor) references wcf3_tag (tagID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_tag_to_object
(
  objectID     int(10) not null,
  tagID        int(10) not null,
  objectTypeID int(10) not null,
  languageID   int(10) not null,
  primary key (objectTypeID, objectID, tagID),
  constraint `9b60229321b65e7cb6059e7a8de6daf9_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade,
  constraint a3e90aa5e05315f2fd636018c44bfb86_fk
    foreign key (tagID) references wcf3_tag (tagID)
      on delete cascade,
  constraint be8a2bfaac2f3c789090d7f889d0d57f_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index a3e90aa5e05315f2fd636018c44bfb86
  on wcf3_tag_to_object (tagID);

create index be8a2bfaac2f3c789090d7f889d0d57f
  on wcf3_tag_to_object (objectTypeID, tagID);

create table wcf3_template_group
(
  templateGroupID         int(10) auto_increment
        primary key,
  parentTemplateGroupID   int(10)                 null,
  templateGroupName       varchar(255) default '' not null,
  templateGroupFolderName varchar(255) default '' not null,
  constraint ccf2f6253f3ea303025ae8e53b81f300_fk
    foreign key (parentTemplateGroupID) references wcf3_template_group (templateGroupID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_template
(
  templateID           int(10) auto_increment
        primary key,
  packageID            int(10)           not null,
  templateName         varchar(191)      not null,
  application          varchar(20)       not null,
  templateGroupID      int(10)           null,
  lastModificationTime int(10) default 0 not null,
  constraint applicationTemplate
    unique (application, templateGroupID, templateName),
  constraint `4aca21d7647d5c750766cd7556c9d12b_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade,
  constraint ca0ddd0a0d61553d452f697f6b8f86a7_fk
    foreign key (templateGroupID) references wcf3_template_group (templateGroupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index templateGroupID
  on wcf3_template (packageID, templateGroupID, templateName);

create table wcf3_template_listener
(
  listenerID   int(10) auto_increment
        primary key,
  packageID    int(10)                               not null,
  name         varchar(80)            default ''     not null,
  environment  enum ('user', 'admin') default 'user' not null,
  templateName varchar(80)            default ''     not null,
  eventName    varchar(50)            default ''     not null,
  templateCode text                                  not null,
  niceValue    tinyint(3)             default 0      not null,
  permissions  text                                  null,
  options      text                                  null,
  constraint `466c04f177700cc194c7185bff57ddf3_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index templateName
  on wcf3_template_listener (environment, templateName);

create table wcf3_trophy
(
  trophyID            int(10) auto_increment
        primary key,
  title               varchar(255)          null,
  description         mediumtext            null,
  categoryID          int(10)               not null,
  type                smallint(1) default 1 null,
  iconFile            mediumtext            null,
  iconName            varchar(255)          null,
  iconColor           varchar(255)          null,
  badgeColor          varchar(255)          null,
  isDisabled          tinyint(1)  default 0 not null,
  awardAutomatically  tinyint(1)  default 0 not null,
  revokeAutomatically tinyint(1)  default 0 not null,
  trophyUseHtml       tinyint(1)  default 0 not null,
  showOrder           int(10)     default 0 not null,
  constraint `0de0ed03e8c50a947a3c56915783dda9_fk`
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_unfurl_url_image
(
  imageID        int(10) auto_increment
        primary key,
  imageUrl       text                 not null,
  imageUrlHash   varchar(40)          not null,
  width          int(10)              not null,
  height         int(10)              not null,
  imageExtension varchar(4)           null,
  isStored       tinyint(1) default 0 not null,
  constraint imageUrlHash
    unique (imageUrlHash)
)
  collate = utf8mb4_unicode_ci;

create table wcf3_unfurl_url
(
  urlID       int(10) auto_increment
        primary key,
  url         text                           not null,
  urlHash     varchar(40)                    not null,
  title       varchar(255) default ''        not null,
  description text                           null,
  imageID     int(10)                        null,
  status      varchar(255) default 'PENDING' not null,
  lastFetch   int(10)      default 0         not null,
  constraint urlHash
    unique (urlHash),
  constraint `41299772562538bdb63edd49aca42ef9_fk`
    foreign key (imageID) references wcf3_unfurl_url_image (imageID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_group
(
  groupID                             int(10) auto_increment
        primary key,
  groupName                           varchar(255) default ''   not null,
  groupDescription                    text                      null,
  groupType                           tinyint(1)   default 4    not null,
  priority                            mediumint(8) default 0    not null,
  userOnlineMarking                   varchar(255) default '%s' not null,
  showOnTeamPage                      tinyint(1)   default 0    not null,
  allowMention                        tinyint(1)   default 0    not null,
  canBeAddedAsConversationParticipant tinyint(1)   default 0    not null,
  requireMultifactor                  tinyint(1)   default 0    not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acl_option_to_group
(
  optionID    int(10)              not null,
  objectID    int(10)              not null,
  groupID     int(10)              not null,
  optionValue tinyint(1) default 0 not null,
  constraint groupID
    unique (groupID, objectID, optionID),
  constraint `4993fc2acb6030be4e2c5817eb5c61ac_fk`
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade,
  constraint `87d28a1e47051305fd6f783bbe9393f1_fk`
    foreign key (optionID) references wcf3_acl_option (optionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acl_simple_to_group
(
  objectTypeID int(10) not null,
  objectID     int(10) not null,
  groupID      int(10) not null,
  constraint groupKey
    unique (objectTypeID, objectID, groupID),
  constraint `3739cbcfb4b8e3bc50a978f188d3f353_fk`
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade,
  constraint `52280824308d328d6c9543c97746141f_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_group_assignment
(
  assignmentID int(10) auto_increment
        primary key,
  groupID      int(10)              not null,
  title        varchar(255)         not null,
  isDisabled   tinyint(1) default 0 not null,
  constraint `844107a137da5eb270e2ec435ac5a765_fk`
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_group_option
(
  optionID          int(10) auto_increment
        primary key,
  packageID         int(10)                 not null,
  optionName        varchar(191) default '' not null,
  categoryName      varchar(191) default '' not null,
  optionType        varchar(255) default '' not null,
  defaultValue      mediumtext              null,
  validationPattern text                    null,
  enableOptions     mediumtext              null,
  showOrder         int(10)      default 0  not null,
  permissions       text                    null,
  options           text                    null,
  usersOnly         tinyint(1)   default 0  not null,
  additionalData    mediumtext              null,
  constraint optionName
    unique (optionName, packageID),
  constraint cbcf3bacc09d8477c307c3387dc31598_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_group_option_category
(
  categoryID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  categoryName       varchar(191) default '' not null,
  parentCategoryName varchar(191) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName),
  constraint b8e62870db5700e650e2f9100805b61b_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_group_option_value
(
  groupID     int(10)    not null,
  optionID    int(10)    not null,
  optionValue mediumtext not null,
  constraint groupID
    unique (groupID, optionID),
  constraint d16106db7a6d027d03c124c233555b91_fk
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade,
  constraint e83c054fb6b6b6f655cac1a1d188a09f_fk
    foreign key (optionID) references wcf3_user_group_option (optionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_menu_item
(
  menuItemID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  menuItem           varchar(191) default '' not null,
  parentMenuItem     varchar(191) default '' not null,
  menuItemController varchar(255) default '' not null,
  menuItemLink       varchar(255) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  className          varchar(255) default '' not null,
  iconClassName      varchar(255) default '' not null,
  constraint menuItem
    unique (menuItem, packageID),
  constraint `3a07c747dd216add8d106bd43ce2de90_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_notification_event
(
  eventID                    int(10) auto_increment
        primary key,
  packageID                  int(10)                                          not null,
  eventName                  varchar(191)                      default ''     not null,
  objectTypeID               int(10)                                          not null,
  className                  varchar(255)                      default ''     not null,
  permissions                text                                             null,
  options                    text                                             null,
  preset                     tinyint(1)                        default 0      not null,
  presetMailNotificationType enum ('none', 'instant', 'daily') default 'none' not null,
  constraint eventName
    unique (eventName, objectTypeID),
  constraint `38f38c2d6ece7d007a9428f71e002406_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint be0e03d5fe86c93ebbf3e5fa8f01c6bb_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_option
(
  optionID              int(10) auto_increment
        primary key,
  packageID             int(10)                 not null,
  optionName            varchar(191) default '' not null,
  categoryName          varchar(191) default '' not null,
  optionType            varchar(255) default '' not null,
  defaultValue          mediumtext              null,
  validationPattern     text                    null,
  selectOptions         mediumtext              null,
  enableOptions         mediumtext              null,
  required              tinyint(1)   default 0  not null,
  askDuringRegistration tinyint(1)   default 0  not null,
  editable              tinyint(1)   default 0  not null,
  visible               tinyint(1)   default 0  not null,
  outputClass           varchar(255) default '' not null,
  searchable            tinyint(1)   default 0  not null,
  showOrder             int(10)      default 0  not null,
  isDisabled            tinyint(1)   default 0  not null,
  permissions           text                    null,
  options               text                    null,
  additionalData        mediumtext              null,
  originIsSystem        tinyint(1)   default 0  not null,
  labeledUrl            mediumtext              null,
  constraint optionName
    unique (optionName, packageID),
  constraint `0497da94a87cce129bfdac361a0e17ae_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index categoryName
  on wcf3_user_option (categoryName);

create table wcf3_user_option_category
(
  categoryID         int(10) auto_increment
        primary key,
  packageID          int(10)                 not null,
  categoryName       varchar(191) default '' not null,
  parentCategoryName varchar(191) default '' not null,
  showOrder          int(10)      default 0  not null,
  permissions        text                    null,
  options            text                    null,
  constraint categoryName
    unique (categoryName),
  constraint `9f3e36f3b3ca1df3756d351705561878_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_profile_menu_item
(
  menuItemID  int(10) auto_increment
        primary key,
  packageID   int(10)           not null,
  menuItem    varchar(191)      not null,
  showOrder   int(10) default 0 not null,
  permissions text              null,
  options     text              null,
  className   varchar(255)      not null,
  constraint packageID
    unique (packageID, menuItem),
  constraint e30af010895398054cb30b05a3ef479c_fk
    foreign key (packageID) references wcf3_package (packageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_rank
(
  rankID         int(10) auto_increment
        primary key,
  groupID        int(10)                 not null,
  requiredPoints int(10)      default 0  not null,
  rankTitle      varchar(255) default '' not null,
  cssClassName   varchar(255) default '' not null,
  rankImage      varchar(255) default '' not null,
  repeatImage    tinyint(3)   default 1  not null,
  requiredGender tinyint(1)   default 0  not null,
  hideTitle      tinyint(1)   default 0  not null,
  constraint fbe596c8b69b627280cf3048d3a88fac_fk
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user
(
  userID                      int(10) auto_increment
        primary key,
  username                    varchar(100) default ''         not null,
  email                       varchar(191) default ''         not null,
  password                    varchar(255) default 'invalid:' not null,
  accessToken                 char(40)     default ''         not null,
  languageID                  int(10)      default 0          not null,
  registrationDate            int(10)      default 0          not null,
  styleID                     int(10)      default 0          not null,
  banned                      tinyint(1)   default 0          not null,
  banReason                   mediumtext                      null,
  banExpires                  int(10)      default 0          not null,
  activationCode              int(10)      default 0          not null,
  lastLostPasswordRequestTime int(10)      default 0          not null,
  lostPasswordKey             char(40)                        null,
  lastUsernameChange          int(10)      default 0          not null,
  newEmail                    varchar(255) default ''         not null,
  oldUsername                 varchar(255) default ''         not null,
  quitStarted                 int(10)      default 0          not null,
  reactivationCode            int(10)      default 0          not null,
  registrationIpAddress       varchar(39)  default ''         not null,
  avatarID                    int(10)                         null,
  disableAvatar               tinyint(1)   default 0          not null,
  disableAvatarReason         text                            null,
  disableAvatarExpires        int(10)      default 0          not null,
  signature                   text                            null,
  signatureEnableHtml         tinyint(1)   default 0          not null,
  disableSignature            tinyint(1)   default 0          not null,
  disableSignatureReason      text                            null,
  disableSignatureExpires     int(10)      default 0          not null,
  lastActivityTime            int(10)      default 0          not null,
  profileHits                 int(10)      default 0          not null,
  rankID                      int(10)                         null,
  userTitle                   varchar(255) default ''         not null,
  userOnlineGroupID           int(10)                         null,
  activityPoints              int(10)      default 0          not null,
  notificationMailToken       varchar(20)  default ''         not null,
  authData                    varchar(191) default ''         not null,
  likesReceived               mediumint(7) default 0          not null,
  wbbPosts                    int(10)      default 0          not null,
  wscConnectToken             char(36)                        null,
  wscConnectThirdPartyToken   char(36)                        null,
  wscConnectLoginDevice       varchar(255)                    null,
  wscConnectLoginTime         int(10)      default 0          null,
  wscConnectPublicKey         text                            null,
  disclaimerAccepted          tinyint(1)   default 0          null,
  disclaimerAcceptedAt        int(10)      default 0          not null,
  disclaimerDeclinedAt        int(10)      default 0          not null,
  trophyPoints                int(10)      default 0          not null,
  coverPhotoHash              char(40)                        null,
  coverPhotoExtension         varchar(4)   default ''         not null,
  disableCoverPhoto           tinyint(1)   default 0          not null,
  disableCoverPhotoReason     text                            null,
  disableCoverPhotoExpires    int(10)      default 0          not null,
  minAgeConfirmedAt           int(10)      default 0          not null,
  wscConnectLoginDevices      text                            null,
  articles                    int(10)      default 0          not null,
  blacklistMatches            varchar(255) default ''         not null,
  marketplaceNearbyDistance   int(10)      default 50         null,
  marketplaceTermsAcceptTime  int(10)                         null,
  marketplaceEntries          int(10)      default 0          not null,
  marketplaceRatingBuyer      text                            null,
  marketplaceRatingSeller     text                            null,
  marketplaceRatingPartner    text                            null,
  galleryImages               int(10)      default 0          not null,
  galleryVideos               int(10)      default 0          not null,
  galleryFavorites            int(10)      default 0          not null,
  emailConfirmed              char(40)                        null,
  wbbBestAnswers              int(10)      default 0          not null,
  coverPhotoHasWebP           tinyint(1)   default 0          not null,
  multifactorActive           tinyint(1)   default 0          not null,
  bookmarks                   int(10)      default 0          null,
  bookmarkShares              int(10)      default 0          null,
  userIPLogWhitelist          int          default 0          not null,
  userIPLogComment            mediumtext                      null,
  constraint username
    unique (username),
  constraint `83582377a31384ebfb8005c99cf6ed08_fk`
    foreign key (rankID) references wcf3_user_rank (rankID)
      on delete set null,
  constraint fcb82ebbacf92efe3570231eb91e29eb_fk
    foreign key (userOnlineGroupID) references wcf3_user_group (groupID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table gallery3_album
(
  albumID        int(10) auto_increment
        primary key,
  userID         int(10)                 null,
  username       varchar(255) default '' not null,
  title          varchar(255) default '' not null,
  description    text                    null,
  images         mediumint(7) default 0  not null,
  videos         mediumint(7) default 0  not null,
  time           int(10)      default 0  not null,
  lastUpdateTime int(10)      default 0  not null,
  coverImageIDs  text                    null,
  accessLevel    tinyint(1)   default 0  not null,
  constraint efdf5f5a954d9288bc85507c8e30dc4e_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index access
  on gallery3_album (accessLevel, userID);

create table gallery3_image
(
  imageID              int(10) auto_increment
        primary key,
  tmpHash              varchar(40)  default ''        not null,
  userID               int(10)                        null,
  username             varchar(255) default ''        not null,
  albumID              int(10)                        null,
  title                varchar(255) default ''        not null,
  description          text                           null,
  filename             varchar(255) default ''        not null,
  fileExtension        varchar(7)   default ''        not null,
  fileHash             varchar(40)  default ''        not null,
  filesize             int(10)      default 0         not null,
  comments             smallint(5)  default 0         not null,
  views                mediumint(8) default 0         not null,
  cumulativeLikes      mediumint(7) default 0         not null,
  favorites            int(10)      default 0         not null,
  uploadTime           int(10)      default 0         not null,
  creationTime         int(10)      default 0         not null,
  width                smallint(5)  default 0         not null,
  height               smallint(5)  default 0         not null,
  orientation          tinyint(1)   default 1         not null,
  camera               varchar(191) default ''        not null,
  location             varchar(255) default ''        not null,
  latitude             float(10, 7) default 0.0000000 not null,
  longitude            float(10, 7) default 0.0000000 not null,
  thumbnailX           smallint(5)  default 0         not null,
  thumbnailY           smallint(5)  default 0         not null,
  thumbnailHeight      smallint(5)  default 0         not null,
  thumbnailWidth       smallint(5)  default 0         not null,
  tinyThumbnailSize    int(10)      default 0         not null,
  smallThumbnailSize   int(10)      default 0         not null,
  mediumThumbnailSize  int(10)      default 0         not null,
  largeThumbnailSize   int(10)      default 0         not null,
  enableHtml           tinyint(1)   default 0         not null,
  ipAddress            varchar(39)  default ''        not null,
  enableComments       tinyint(1)   default 1         not null,
  isDisabled           tinyint(1)   default 0         not null,
  isDeleted            tinyint(1)   default 0         not null,
  deleteTime           int(10)      default 0         not null,
  rawExifData          mediumtext                     null,
  exifData             mediumtext                     null,
  accessLevel          tinyint(1)   default 0         not null,
  hasEmbeddedObjects   tinyint(1)   default 0         not null,
  hasMarkers           tinyint(1)   default 0         not null,
  showOrder            int(10)      default 0         not null,
  hasOriginalWatermark tinyint(1)   default 0         not null,
  isVideo              tinyint(1)   default 0         not null,
  videoFilename        varchar(255) default ''        not null,
  videoFileExtension   varchar(7)   default ''        not null,
  videoFileHash        varchar(40)  default ''        not null,
  videoFilesize        bigint       default 0         not null,
  isVideoLink          tinyint(1)   default 0         not null,
  videoLink            varchar(255) default ''        not null,
  videoProviderID      int(10)                        null,
  constraint `2273bdf56ae653692c93ab2b04e13eaa_fk`
    foreign key (videoProviderID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `5568b33bcfedf6d12713788694d316f5_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint `99913065385df09919eaf01598baa79a_fk`
    foreign key (albumID) references gallery3_album (albumID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table gallery3_favorite
(
  imageID int(10) not null,
  userID  int(10) not null,
  constraint imageID
    unique (imageID, userID),
  constraint `23dfda7d790a2bce605aeb6a6e8fb3ed_fk`
    foreign key (imageID) references gallery3_image (imageID)
      on delete cascade,
  constraint `8f124cc88b247014c751a03a6b2d3174_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index access
  on gallery3_image (accessLevel, userID);

create index camera
  on gallery3_image (camera);

create index hasLargeThumbnail
  on gallery3_image (largeThumbnailSize);

create index tmpHash
  on gallery3_image (tmpHash);

create index video
  on gallery3_image (isVideo, isVideoLink);

create table gallery3_image_marker
(
  markerID    int(10) auto_increment
        primary key,
  imageID     int(10)               not null,
  positionX   smallint(5) default 0 not null,
  positionY   smallint(5) default 0 not null,
  userID      int(10)               null,
  description text                  null,
  constraint `1df58d11e854215e8dec4f5418f34f9d_fk`
    foreign key (imageID) references gallery3_image (imageID)
      on delete cascade,
  constraint ff78bebbb59c873b6376101ed7abe57c_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index imageID
  on gallery3_image_marker (imageID);

create table gallery3_image_to_category
(
  categoryID int(10) not null,
  imageID    int(10) not null,
  primary key (categoryID, imageID),
  constraint `6c024503240b7f8fad8cb4465f7b9265_fk`
    foreign key (imageID) references gallery3_image (imageID)
      on delete cascade,
  constraint `7b75e9fe36db2d04bc9a3f4eead7c9fc_fk`
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_board_user_status
(
  userID  int(10)      not null,
  boardID int(10)      not null,
  status  varchar(255) null,
  primary key (userID, boardID),
  constraint `42f02307c2c07cd69c405e14093c633a_fk`
    foreign key (boardID) references wbb3_board (boardID)
      on delete cascade,
  constraint ea89398f3972055bb643056b08a23267_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index userID_status
  on wbb3_board_user_status (userID, status);

create table wbb3_post
(
  postID             int(10) auto_increment
        primary key,
  threadID           int(10)                 not null,
  userID             int(10)                 null,
  username           varchar(255) default '' not null,
  subject            varchar(255) default '' not null,
  message            mediumtext              not null,
  time               int(10)      default 0  not null,
  isDeleted          tinyint(1)   default 0  not null,
  isDisabled         tinyint(1)   default 0  not null,
  isClosed           tinyint(1)   default 0  not null,
  editorID           int(10)                 null,
  editor             varchar(255) default '' not null,
  lastEditTime       int(10)      default 0  not null,
  editCount          mediumint(7) default 0  not null,
  editReason         text                    null,
  lastVersionTime    int(10)      default 0  not null,
  attachments        smallint(5)  default 0  not null,
  pollID             int(10)                 null,
  enableHtml         tinyint(1)   default 0  not null,
  ipAddress          varchar(39)  default '' not null,
  cumulativeLikes    mediumint(7) default 0  not null,
  deleteTime         int(10)      default 0  not null,
  enableTime         int(10)      default 0  not null,
  hasEmbeddedObjects tinyint(1)   default 0  not null,
  isOfficial         tinyint(1)   default 0  not null,
  constraint `1c2156d1d8b5e9148f3887c9ca306b20_fk`
    foreign key (pollID) references wcf3_poll (pollID)
      on delete set null,
  constraint a3ab1102e5907d523eaae433d491d7c4_fk
    foreign key (editorID) references wcf3_user (userID)
      on delete set null,
  constraint e06551fc8a2adad23ffa1a1d7863cd6e_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index enableTime
  on wbb3_post (enableTime);

create index ipAddress
  on wbb3_post (ipAddress);

create index isDeleted
  on wbb3_post (isDeleted);

create index isOfficial
  on wbb3_post (threadID, isOfficial);

create index threadID
  on wbb3_post (threadID, userID);

create index threadID_2
  on wbb3_post (threadID, isDeleted, isDisabled, time);

create index thread_3
  on wbb3_post (threadID, isDisabled, userID, time);

create index userToPost
  on wbb3_post (userID, isDeleted, isDisabled, threadID);

create table wbb3_rss_feed
(
  feedID              int(10) auto_increment
        primary key,
  title               varchar(255) default ''   not null,
  url                 text                      null,
  isDisabled          tinyint(1)   default 0    not null,
  lastRun             int(10)      default 0    not null,
  cycleTime           mediumint(5) default 1800 not null,
  maxResults          smallint(5)  default 0    not null,
  searchKeywords      text                      null,
  boardID             int(10)                   null,
  userID              int(10)                   null,
  languageID          int(10)                   null,
  closeThread         tinyint(1)   default 0    not null,
  disableThread       tinyint(1)   default 0    not null,
  threadTags          text                      null,
  useCategoriesAsTags tinyint(1)   default 0    not null,
  errorMessage        text                      null,
  constraint `6e7cb159bb1d1895720c7da2ceec3383_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint d2210c93f4851b57737d0236e5894ab4_fk
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null,
  constraint ee28fd224d0bffbdc51c1926980e6800_fk
    foreign key (boardID) references wbb3_board (boardID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wbb3_thread
(
  threadID         int(10) auto_increment
        primary key,
  boardID          int(10)                 not null,
  languageID       int(10)                 null,
  topic            varchar(255) default '' not null,
  firstPostID      int(10)                 null,
  time             int(10)      default 0  not null,
  userID           int(10)                 null,
  username         varchar(255) default '' not null,
  lastPostID       int(10)                 null,
  lastPostTime     int(10)      default 0  not null,
  lastPosterID     int(10)                 null,
  lastPoster       varchar(255) default '' not null,
  replies          int(10)      default 0  not null,
  views            int(10)      default 0  not null,
  attachments      int(10)      default 0  not null,
  polls            int(10)      default 0  not null,
  isAnnouncement   tinyint(1)   default 0  not null,
  isSticky         tinyint(1)   default 0  not null,
  isDisabled       tinyint(1)   default 0  not null,
  isClosed         tinyint(1)   default 0  not null,
  isDeleted        tinyint(1)   default 0  not null,
  movedThreadID    int(10)                 null,
  movedTime        int(10)      default 0  not null,
  isDone           tinyint(1)   default 0  not null,
  cumulativeLikes  mediumint(7) default 0  not null,
  hasLabels        tinyint(1)   default 0  not null,
  deleteTime       int(10)      default 0  not null,
  bestAnswerPostID int(10)                 null,
  constraint `04ebec36802ce1700897ac86a2ebe021_fk`
    foreign key (movedThreadID) references wbb3_thread (threadID)
      on delete cascade,
  constraint `3db7faa03743201c9768fce300814325_fk`
    foreign key (bestAnswerPostID) references wbb3_post (postID)
      on delete set null,
  constraint `736e1c777838898753717145c74504b0_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint ce9e37c5ce8bb219c20b1292b4cd27dc_fk
    foreign key (lastPosterID) references wcf3_user (userID)
      on delete set null,
  constraint d2a5f38a922a01ae9efbce333d38995a_fk
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null,
  constraint e6c0fdf599452040fc9e2b5db0f1b666_fk
    foreign key (boardID) references wbb3_board (boardID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_board_last_post
(
  boardID    int(10) not null,
  languageID int(10) null,
  threadID   int(10) not null,
  constraint `67cc5c3ec3031d0c70e2f54fca1dbc48_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade,
  constraint `8fcebba0a4d6677f5b0bbb52c2495ef8_fk`
    foreign key (boardID) references wbb3_board (boardID)
      on delete cascade,
  constraint fd77f75da3f8721908b574671d2f8bec_fk
    foreign key (threadID) references wbb3_thread (threadID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index boardID
  on wbb3_board_last_post (boardID, languageID);

alter table wbb3_post
  add constraint `8d74135323f14f0b1ca27cdc4da47d1a_fk`
  foreign key (threadID) references wbb3_thread (threadID)
  on delete cascade;

create table wbb3_rss_feed_log
(
  feedID   int(10)                not null,
  hash     varchar(40) default '' not null,
  threadID int(10)                null,
  constraint feedID
    unique (feedID, hash),
  constraint `8da2449b181b06a01bbeda4b3ca87fc0_fk`
    foreign key (feedID) references wbb3_rss_feed (feedID)
      on delete cascade,
  constraint `98e78725f047e17ac6e63b3b5eec57f6_fk`
    foreign key (threadID) references wbb3_thread (threadID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index boardID
  on wbb3_thread (boardID, isAnnouncement, isSticky, lastPostTime, isDeleted, isDisabled);

create index boardID_2
  on wbb3_thread (boardID, isDeleted, isDisabled, movedThreadID);

create index lastPostTime
  on wbb3_thread (lastPostTime);

create index movedTime
  on wbb3_thread (movedTime);

create index privateLastPost
  on wbb3_thread (boardID, isDeleted, isDisabled, movedThreadID, userID, lastPostTime, languageID);

create table wbb3_thread_announcement
(
  boardID  int(10) not null,
  threadID int(10) not null,
  primary key (boardID, threadID),
  constraint e79cd92e8c64f17f2a3d2e14821735ec_fk
    foreign key (boardID) references wbb3_board (boardID)
      on delete cascade,
  constraint f5f65b58116930bc0be1c8e39ebd446a_fk
    foreign key (threadID) references wbb3_thread (threadID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_thread_form_option_value
(
  postID      int(10)    not null,
  optionID    int(10)    not null,
  optionValue mediumtext not null,
  constraint postID
    unique (postID, optionID),
  constraint b4a3d50a833cd91cca03ec1032bb9367_fk
    foreign key (postID) references wbb3_post (postID)
      on delete cascade,
  constraint d077b5bed0f135e44302e7ff2c7a1baf_fk
    foreign key (optionID) references wbb3_thread_form_option (optionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_thread_similar
(
  threadID        int(10) not null,
  similarThreadID int(10) not null,
  constraint threadID
    unique (threadID, similarThreadID),
  constraint `597a8fc8f5adfaedddfa3a0c6f8382e8_fk`
    foreign key (threadID) references wbb3_thread (threadID)
      on delete cascade,
  constraint `94f32a3002188a16f304bed28b17b992_fk`
    foreign key (similarThreadID) references wbb3_thread (threadID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wbb3_thread_user_status
(
  userID   int(10)      not null,
  threadID int(10)      not null,
  status   varchar(255) null,
  primary key (userID, threadID),
  constraint `644f698c1541a27e036e618868363e2d_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `9b97d29d7db69da7238160c349b5442b_fk`
    foreign key (threadID) references wbb3_thread (threadID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index userID_status
  on wbb3_thread_user_status (userID, status);

create table wcf3_acl_option_to_user
(
  optionID    int(10)              not null,
  objectID    int(10)              not null,
  userID      int(10)              not null,
  optionValue tinyint(1) default 0 not null,
  constraint userID
    unique (userID, objectID, optionID),
  constraint `121a4538d269b38bd52168b137bca7b5_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `599e8c258e275eaaa6e9e2ec021f5373_fk`
    foreign key (optionID) references wcf3_acl_option (optionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acl_simple_to_user
(
  objectTypeID int(10) not null,
  objectID     int(10) not null,
  userID       int(10) not null,
  constraint userKey
    unique (objectTypeID, objectID, userID),
  constraint `924c1b0463c5952b71ad324d927ff0ca_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint e821e424279a7c7dfc7c4156a8a6f604_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acp_dashboard_box_to_user
(
  boxName   varchar(191)         not null,
  userID    int(10)              not null,
  enabled   tinyint(1) default 0 not null,
  showOrder int(10)    default 0 not null,
  constraint boxToUser
    unique (boxName, userID),
  constraint `09e6e9c2637cb7fc7487e3721bb89b3e_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_acp_session_log
(
  sessionLogID     int(10) auto_increment
        primary key,
  sessionID        char(40)     default '' not null,
  userID           int(10)                 null,
  ipAddress        varchar(39)  default '' not null,
  hostname         varchar(255) default '' not null,
  userAgent        varchar(255) default '' not null,
  time             int(10)      default 0  not null,
  lastActivityTime int(10)      default 0  not null,
  constraint `7e892418732f2a7bb265712cde664971_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_acp_session_access_log
(
  sessionAccessLogID int(10) auto_increment
        primary key,
  sessionLogID       int(10)                 not null,
  ipAddress          varchar(39)  default '' not null,
  time               int(10)      default 0  not null,
  requestURI         varchar(255) default '' not null,
  requestMethod      varchar(255) default '' not null,
  className          varchar(255) default '' not null,
  constraint `6cfe8d8ee6fe099fbdf4dc584b6bacdc_fk`
    foreign key (sessionLogID) references wcf3_acp_session_log (sessionLogID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index sessionLogID
  on wcf3_acp_session_access_log (sessionLogID);

create index sessionID
  on wcf3_acp_session_log (sessionID);

create table wcf3_article
(
  articleID         int(10) auto_increment
        primary key,
  userID            int(10)                 null,
  username          varchar(255) default '' not null,
  time              int(10)      default 0  not null,
  categoryID        int(10)                 not null,
  isMultilingual    tinyint(1)   default 0  not null,
  publicationStatus tinyint(1)   default 1  not null,
  publicationDate   int(10)      default 0  not null,
  enableComments    tinyint(1)   default 1  not null,
  views             mediumint(7) default 0  not null,
  cumulativeLikes   mediumint(7) default 0  not null,
  isDeleted         tinyint(1)   default 0  not null,
  hasLabels         tinyint(1)   default 0  not null,
  attachments       smallint(5)  default 0  not null,
  constraint `0bdaafec45e526a59e2bf2eda733f217_fk`
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete cascade,
  constraint `42f35b7ed4a7e31e473c1b807c3d839b_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index time
  on wcf3_article (time);

create table wcf3_article_version
(
  versionID int(10) auto_increment
        primary key,
  objectID  int(10)      not null,
  userID    int(10)      null,
  username  varchar(100) not null,
  time      int(10)      not null,
  data      longblob     null,
  constraint `08f6ce26dd5d03e70f764dd4b136e286_fk`
    foreign key (objectID) references wcf3_article (articleID)
      on delete cascade,
  constraint b37c7810d4f80b0eefb1f404e46dd832_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
comment 'Version tracking for com.woltlab.wcf.article' collate = utf8mb4_unicode_ci;

create table wcf3_attachment
(
  attachmentID        int(10) auto_increment
        primary key,
  objectTypeID        int(10)                 not null,
  objectID            int(10)                 null,
  userID              int(10)                 null,
  tmpHash             varchar(40)  default '' not null,
  filename            varchar(255) default '' not null,
  filesize            int(10)      default 0  not null,
  fileType            varchar(255) default '' not null,
  fileHash            varchar(40)  default '' not null,
  isImage             tinyint(1)   default 0  not null,
  width               smallint(5)  default 0  not null,
  height              smallint(5)  default 0  not null,
  tinyThumbnailType   varchar(255) default '' not null,
  tinyThumbnailSize   int(10)      default 0  not null,
  tinyThumbnailWidth  smallint(5)  default 0  not null,
  tinyThumbnailHeight smallint(5)  default 0  not null,
  thumbnailType       varchar(255) default '' not null,
  thumbnailSize       int(10)      default 0  not null,
  thumbnailWidth      smallint(5)  default 0  not null,
  thumbnailHeight     smallint(5)  default 0  not null,
  downloads           int(10)      default 0  not null,
  lastDownloadTime    int(10)      default 0  not null,
  uploadTime          int(10)      default 0  not null,
  showOrder           smallint(5)  default 0  not null,
  fileID              int                     null,
  thumbnailID         int                     null,
  tinyThumbnailID     int                     null,
  constraint `25954e28e63e9d48b9147db1dcd68b0e_fk`
    foreign key (tinyThumbnailID) references wcf3_file_thumbnail (thumbnailID)
      on delete set null,
  constraint c4ed06b0f219ba6baa5d43cd85e17891_fk
    foreign key (fileID) references wcf3_file (fileID)
      on delete set null,
  constraint f1156f12e0017f4ad1c371e0a278d3d5_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint fcab7f5171e39303172c181ea698b08a_fk
    foreign key (thumbnailID) references wcf3_file_thumbnail (thumbnailID)
      on delete set null,
  constraint fcbbb0ccb471772d96447a8d73ff9a18_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table marketplace3_entry
(
  entryID                int(10) auto_increment
        primary key,
  type                   enum ('offer', 'search', 'exchange', 'giveAway') null,
  userID                 int(10)                                          null,
  username               varchar(255) default ''                          not null,
  subject                varchar(191) default ''                          not null,
  message                longtext                                         null,
  price                  varchar(50)  default ''                          not null,
  time                   int(10)      default 0                           not null,
  languageID             int(10)                                          null,
  attachments            smallint(5)  default 0                           not null,
  attachmentPreviewID    int(10)                                          null,
  comments               smallint(5)  default 0                           not null,
  views                  mediumint(7) default 0                           not null,
  cumulativeLikes        mediumint(7) default 0                           not null,
  enableHtml             tinyint(1)   default 0                           not null,
  enableComments         tinyint(1)   default 1                           not null,
  isDisabled             tinyint(1)   default 0                           not null,
  isCompleted            tinyint(1)   default 0                           not null,
  ipAddress              varchar(39)                                      null,
  name                   varchar(255)                                     null,
  email                  varchar(255)                                     null,
  phone                  varchar(255)                                     null,
  street                 varchar(255)                                     null,
  city                   varchar(255)                                     null,
  zipcode                varchar(50)                                      null,
  country                varchar(255)                                     null,
  lat                    double(10, 7)                                    null,
    lng                    double(10, 7)                                    null,
    editCount              int(10)      default 0                           not null,
    lastEditTime           int(10)      default 0                           not null,
    expire                 int(10)                                          null,
    ratingByOwner          int(10)                                          null,
    ratingByAccepter       int(10)                                          null,
    hasEmbeddedObjects     tinyint(1)   default 0                           not null,
    buyer                  int                                              null,
    openOfferCount         int(5)       default 0                           not null,
    isRenewed              tinyint(1)                                       null,
    sortOrder              int(5)                                           null,
    expireNotificationSent tinyint(1)   default 0                           not null,
    currency               varchar(20)                                      null,
    hasLabels              tinyint(1)   default 0                           not null,
    image                  varchar(255)                                     null,
    imageLarge             varchar(255)                                     null,
    deleteTime             int(5)                                           null,
    isDeleted              tinyint(1)   default 0                           not null,
    constraint `1e7c1a8ea7c41f24bd79a08ae7f95aa6_fk`
        foreign key (attachmentPreviewID) references wcf3_attachment (attachmentID)
            on delete set null,
    constraint `448cce4d3a4d3578ebbd993624ef2b9e_fk`
        foreign key (buyer) references wcf3_user (userID)
            on delete set null,
    constraint `674c548de476bdcd2e303d44c749a04a_fk`
        foreign key (userID) references wcf3_user (userID)
            on delete set null,
    constraint ad3a5303f0603a13c74fa9ac8864e6e0_fk
        foreign key (languageID) references wcf3_language (languageID)
            on delete set null
)
  collate = utf8mb4_unicode_ci;

create index attachmentPreviewID
  on marketplace3_entry (attachmentPreviewID);

create index comments
  on marketplace3_entry (comments);

create index expire
  on marketplace3_entry (expire);

create index isDeleted
  on marketplace3_entry (isDeleted);

create index isDisabled
  on marketplace3_entry (isDisabled);

create index languageID
  on marketplace3_entry (languageID);

create index lat
  on marketplace3_entry (lat);

create index lng
  on marketplace3_entry (lng);

create index openOfferCount
  on marketplace3_entry (openOfferCount);

create index ratingByAccepter
  on marketplace3_entry (ratingByAccepter);

create index ratingByOwner
  on marketplace3_entry (ratingByOwner);

create index sortOrder
  on marketplace3_entry (sortOrder);

create index time
  on marketplace3_entry (time);

create index type
  on marketplace3_entry (type);

create index userID
  on marketplace3_entry (userID);

create table marketplace3_entry_option_value
(
  entryID int(10) not null
        primary key,
  option1 text    null,
  option2 text    null,
  constraint c921e0e412486d0d071a994ec098218c_fk
    foreign key (entryID) references marketplace3_entry (entryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table marketplace3_entry_sharing
(
  entryID int(10) not null,
  userID  int(10) not null,
  constraint entryID
    unique (entryID, userID),
  constraint `6b7949c8418aa40b169167373f030ad9_fk`
    foreign key (entryID) references marketplace3_entry (entryID)
      on delete cascade,
  constraint b2a135cb7f9d93a7209cbc7447aec452_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table marketplace3_entry_to_category
(
  categoryID int(10) not null,
  entryID    int(10) not null,
  primary key (categoryID, entryID),
  constraint aae1923d9e298ad94f5685a2ea52b2b8_fk
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete cascade,
  constraint c24156d0962d9a656e46ec652c2da219_fk
    foreign key (entryID) references marketplace3_entry (entryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index entryID
  on marketplace3_entry_to_category (entryID);

create table marketplace3_offer
(
  offerID  int(10) auto_increment
        primary key,
  userID   int(10)                                                                  not null,
  objectID int(10)                                                                  not null,
  time     int(10)                                                                  not null,
  price    varchar(255)                                                             null,
  reason   text                                                                     not null,
  status   enum ('undecided', 'accepted', 'declined', 'manual') default 'undecided' not null,
  constraint `1b4cdad47b19c53bb633c6edd30f0af3_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `8fe6c33f6ceb11b56a6a64ddcc162ffa_fk`
    foreign key (objectID) references marketplace3_entry (entryID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectID
  on marketplace3_offer (objectID);

create index userID
  on marketplace3_offer (userID);

create table marketplace3_rating
(
  ratingID           int(10) auto_increment
        primary key,
  entryID            int(10)                             null,
  entrySubject       varchar(255)                        not null,
  subject            varchar(255)                        not null,
  time               int(5)                              not null,
  userID             int(10)                             null,
  username           varchar(255)                        not null,
  message            text                                not null,
  type               enum ('buyer', 'seller', 'partner') not null,
  isActive           tinyint(1)   default 1              not null,
  attachments        int(5)       default 0              not null,
  ipAddress          varchar(39)                         null,
  ratedUserID        int(10)                             null,
  ratedUsername      varchar(255) default ''             not null,
  response           text                                null,
  responseTime       int(5)                              null,
  hasEmbeddedObjects tinyint(1)   default 0              not null,
  constraint `4a9311dd1b4fd1c93041415a5df4145f_fk`
    foreign key (entryID) references marketplace3_entry (entryID)
      on delete set null,
  constraint f47fa1ffb61944e0fbcc8604d39afde7_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

alter table marketplace3_entry
  add constraint `4c02b1d369613d7e49b98c25a700c2e5_fk`
  foreign key (ratingByOwner) references marketplace3_rating (ratingID)
  on delete set null;

alter table marketplace3_entry
  add constraint `8a10546db23894d1235c1744655be630_fk`
  foreign key (ratingByAccepter) references marketplace3_rating (ratingID)
  on delete set null;

create index entryID
  on marketplace3_rating (entryID);

create index isActive
  on marketplace3_rating (isActive);

create index time
  on marketplace3_rating (time);

create index type
  on marketplace3_rating (type);

create index userID
  on marketplace3_rating (userID);

create table marketplace3_rating_value
(
  ratingValueID    int(10) auto_increment
        primary key,
  ratingID         int(10)      not null,
  ratingCategoryID int(10)      not null,
  value            varchar(255) not null,
  constraint `07da67390ed2dde2d90eddb5af0b2e06_fk`
    foreign key (ratingCategoryID) references marketplace3_rating_category (ratingCategoryID)
      on delete cascade,
  constraint `6c237b0c76b36c171c4cd6cc6c87c9e8_fk`
    foreign key (ratingID) references marketplace3_rating (ratingID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index ratingCategoryID
  on marketplace3_rating_value (ratingCategoryID);

create index ratingID
  on marketplace3_rating_value (ratingID);

create index ratingValueID
  on marketplace3_rating_value (ratingValueID);

create index objectID
  on wcf3_attachment (objectID, uploadTime);

create index objectTypeID
  on wcf3_attachment (objectTypeID, objectID);

create index objectTypeID_2
  on wcf3_attachment (objectTypeID, tmpHash);

create table wcf3_bookmark
(
  bookmarkID int(10) auto_increment
        primary key,
  editID     int(10)                 null,
  editName   varchar(255) default '' not null,
  editTime   int(10)                 null,
  isExternal tinyint(1)   default 0  not null,
  isPrivate  tinyint(1)   default 0  not null,
  objectID   int(10)      default 0  not null,
  remark     text                    not null,
  shareFrom  varchar(255) default '' not null,
  shareWith  text                    not null,
  time       int(10)      default 0  null,
  title      varchar(255) default '' not null,
  type       varchar(20)  default '' not null,
  url        text                    not null,
  userID     int(10)                 null,
  username   varchar(255) default '' not null,
  constraint `6e29b7c9c37985495a2140206177c9df_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index type
  on wcf3_bookmark (type);

create index userID
  on wcf3_bookmark (userID);

create table wcf3_bookmark_share
(
  shareID       int(10) auto_increment
        primary key,
  accepted      tinyint(1)   default 0  not null,
  bookmarkID    int(10)                 not null,
  lastVisitTime int(10)      default 0  not null,
  remark        mediumtext              null,
  receiverID    int(10)                 not null,
  receiverName  varchar(255) default '' not null,
  refused       tinyint(1)   default 0  not null,
  time          int(10)      default 0  null,
  userID        int(10)                 null,
  username      varchar(255) default '' not null,
  constraint `57ed12384a9db8be3c175ccb8accf70c_fk`
    foreign key (bookmarkID) references wcf3_bookmark (bookmarkID)
      on delete cascade,
  constraint b2196c5ef5ca6164c5402ca7339a6f2d_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint ed4052967b1f7df3b29fbee4f84def3f_fk
    foreign key (receiverID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index receiverID
  on wcf3_bookmark_share (receiverID);

create index userID
  on wcf3_bookmark_share (userID);

create table wcf3_box_version
(
  versionID int(10) auto_increment
        primary key,
  objectID  int(10)      not null,
  userID    int(10)      null,
  username  varchar(100) not null,
  time      int(10)      not null,
  data      longblob     null,
  constraint `212f7b1a45ec61539acf555fd4aae550_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint `36d4f3889b8d82c8272bc219a06f63bf_fk`
    foreign key (objectID) references wcf3_box (boxID)
      on delete cascade
)
comment 'Version tracking for com.woltlab.wcf.box' collate = utf8mb4_unicode_ci;

create table wcf3_comment
(
  commentID             int(10) auto_increment
        primary key,
  objectTypeID          int(10)                 not null,
  objectID              int(10)                 not null,
  time                  int(10)      default 0  not null,
  userID                int(10)                 null,
  username              varchar(255)            not null,
  message               mediumtext              not null,
  responses             mediumint(7) default 0  not null,
  responseIDs           varchar(255) default '' not null,
  unfilteredResponses   mediumint(7) default 0  not null,
  unfilteredResponseIDs varchar(255) default '' not null,
  enableHtml            tinyint(1)   default 0  not null,
  isDisabled            tinyint(1)   default 0  not null,
  hasEmbeddedObjects    tinyint(1)   default 0  not null,
  constraint `84ef95cd4d1d3f6ffddca3b3a9ffdb4b_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint af5d6c0034c755660ba589a107195b63_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index `84ef95cd4d1d3f6ffddca3b3a9ffdb4b`
  on wcf3_comment (objectTypeID, objectID, isDisabled, time);

create index lastCommentTime
  on wcf3_comment (userID, time);

create table wcf3_comment_response
(
  responseID         int(10) auto_increment
        primary key,
  commentID          int(10)              not null,
  time               int(10)    default 0 not null,
  userID             int(10)              null,
  username           varchar(255)         not null,
  message            mediumtext           not null,
  enableHtml         tinyint(1) default 0 not null,
  isDisabled         tinyint(1) default 0 not null,
  hasEmbeddedObjects tinyint(1) default 0 not null,
  constraint `3b49de476cb269c037ab92a265729150_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint c4eefcbe8d7b5456996c13d8afe5e535_fk
    foreign key (commentID) references wcf3_comment (commentID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index c4eefcbe8d7b5456996c13d8afe5e535
  on wcf3_comment_response (commentID, isDisabled, time);

create index lastResponseTime
  on wcf3_comment_response (userID, time);

create table wcf3_contact_attachment
(
  attachmentID int(10)  not null,
  accessKey    char(40) not null,
  constraint `7c38f33970fbbd068752853056a8842d_fk`
    foreign key (attachmentID) references wcf3_attachment (attachmentID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_conversation
(
  conversationID       int(10) auto_increment
        primary key,
  subject              varchar(255) default '' not null,
  time                 int(10)      default 0  not null,
  firstMessageID       int(10)                 null,
  userID               int(10)                 null,
  username             varchar(255) default '' not null,
  lastPostTime         int(10)      default 0  not null,
  lastPosterID         int(10)                 null,
  lastPoster           varchar(255) default '' not null,
  replies              mediumint(7) default 0  not null,
  attachments          smallint(5)  default 0  not null,
  participants         mediumint(7) default 0  not null,
  participantSummary   text                    null,
  participantCanInvite tinyint(1)   default 0  not null,
  isClosed             tinyint(1)   default 0  not null,
  isDraft              tinyint(1)   default 0  not null,
  draftData            mediumtext              null,
  constraint `5aec34b7346cdebd49b59463aef8e38a_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint `9d753891c8cc86dccd404a482e203c20_fk`
    foreign key (lastPosterID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index userID
  on wcf3_conversation (userID, isDraft);

create table wcf3_conversation_label
(
  labelID      int(10) auto_increment
        primary key,
  userID       int(10)                 not null,
  label        varchar(80)  default '' not null,
  cssClassName varchar(255) default '' not null,
  constraint `86c7265b56d1082853e89cb043a53857_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_conversation_label_to_object
(
  labelID        int(10) not null,
  conversationID int(10) not null,
  constraint labelID
    unique (labelID, conversationID),
  constraint `46ada3b1be8fc298d7d2200ee4b74261_fk`
    foreign key (labelID) references wcf3_conversation_label (labelID)
      on delete cascade,
  constraint fcc9e4d706a8bf5bf2e950f00a52e89b_fk
    foreign key (conversationID) references wcf3_conversation (conversationID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_conversation_message
(
  messageID          int(10) auto_increment
        primary key,
  conversationID     int(10)                 not null,
  userID             int(10)                 null,
  username           varchar(255) default '' not null,
  message            mediumtext              not null,
  time               int(10)      default 0  not null,
  attachments        smallint(5)  default 0  not null,
  enableHtml         tinyint(1)   default 0  not null,
  ipAddress          varchar(39)  default '' not null,
  lastEditTime       int(10)      default 0  not null,
  editCount          mediumint(7) default 0  not null,
  hasEmbeddedObjects tinyint(1)   default 0  not null,
  constraint `7fa15f013fd4ee4640e10a6641560fe3_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint bbc548fa72c184460ea0e093f3433f58_fk
    foreign key (conversationID) references wcf3_conversation (conversationID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

alter table wcf3_conversation
  add constraint `8408f04786c419f33a015dab069e0f38_fk`
  foreign key (firstMessageID) references wcf3_conversation_message (messageID)
  on delete set null;

create index conversationID
  on wcf3_conversation_message (conversationID, userID);

create index ipAddress
  on wcf3_conversation_message (ipAddress);

create table wcf3_conversation_to_user
(
  conversationID   int(10)                 not null,
  participantID    int(10)                 null,
  username         varchar(255) default '' not null,
  hideConversation tinyint(1)   default 0  not null,
  isInvisible      tinyint(1)   default 0  not null,
  lastVisitTime    int(10)      default 0  not null,
  joinedAt         int(10)      default 0  not null,
  leftAt           int(10)      default 0  not null,
  lastMessageID    int(10)                 null,
  leftByOwnChoice  tinyint(1)   default 1  not null,
  constraint participantID
    unique (participantID, conversationID),
  constraint `69a36e2636fa762ae5fcafcdbf6db706_fk`
    foreign key (conversationID) references wcf3_conversation (conversationID)
      on delete cascade,
  constraint `84c9c259a905e7dbe17fb7fc2988be7e_fk`
    foreign key (lastMessageID) references wcf3_conversation_message (messageID)
      on delete set null,
  constraint ef4f21eb8d1c45cb4c6564a6a96b2e81_fk
    foreign key (participantID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index participantID_2
  on wcf3_conversation_to_user (participantID, hideConversation);

create table wcf3_edit_history_entry
(
  entryID           int(10) auto_increment
        primary key,
  objectTypeID      int(10)                 not null,
  objectID          int(10)                 not null,
  userID            int(10)                 null,
  username          varchar(255) default '' not null,
  time              int(10)      default 0  not null,
  obsoletedAt       int(10)      default 0  not null,
  obsoletedByUserID int(10)                 null,
  message           mediumtext              null,
  editReason        text                    null,
  constraint c004932e54284f233a376b73d40d3f4a_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint d6c1837346261092f677cdf0b4b85bce_fk
    foreign key (obsoletedByUserID) references wcf3_user (userID)
      on delete set null,
  constraint ed692d51f593ee45b4750890ac7ffd65_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID
  on wcf3_edit_history_entry (objectTypeID, objectID);

create index obsoletedAt
  on wcf3_edit_history_entry (obsoletedAt, obsoletedByUserID);

create table wcf3_email_log_entry
(
  entryID     int(10) auto_increment
        primary key,
  time        int(10)      not null,
  messageID   varchar(255) not null,
  subject     varchar(255) not null,
  recipient   varchar(255) not null,
  recipientID int(10)      null,
  status      varchar(255) not null,
  message     text         null,
  constraint ed5f420425e3c794edc8b6381a8d24bf_fk
    foreign key (recipientID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index time
  on wcf3_email_log_entry (time);

create table wcf3_like
(
  likeID         int(10) auto_increment
        primary key,
  objectID       int(10)    default 0 not null,
  objectTypeID   int(10)              not null,
  objectUserID   int(10)              null,
  userID         int(10)              not null,
  time           int(10)    default 1 not null,
  likeValue      tinyint(1) default 1 not null,
  reactionTypeID int(10)              not null,
  constraint objectTypeID
    unique (objectTypeID, objectID, userID),
  constraint `1879baa27836a81658431508c323f7d0_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `7105987cc16c43473fb8bce57244277a_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `7a30a814f4a560672ee5c2c76decc7df_fk`
    foreign key (objectUserID) references wcf3_user (userID)
      on delete set null,
  constraint f8fb06b641ee0150fdf346b770259d13_fk
    foreign key (reactionTypeID) references wcf3_reaction_type (reactionTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index fe5076ee92a558ce8177e3afbfc3dafc_fk
  on wcf3_like (reactionTypeID);

create table wcf3_like_object
(
  likeObjectID    int(10) auto_increment
        primary key,
  objectTypeID    int(10)                not null,
  objectID        int(10)      default 0 not null,
  objectUserID    int(10)                null,
  likes           mediumint(7) default 0 not null,
  dislikes        mediumint(7) default 0 not null,
  cumulativeLikes mediumint(7) default 0 not null,
  cachedUsers     text                   null,
  cachedReactions text                   null,
  constraint objectTypeID
    unique (objectTypeID, objectID),
  constraint `77beccd9b15be36581326534d67e32d2_fk`
    foreign key (objectUserID) references wcf3_user (userID)
      on delete set null,
  constraint `933d3b6dd7369c559233961de642aea9_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_media
(
  mediaID               int(10) auto_increment
        primary key,
  filename              varchar(255) default '' not null,
  filesize              int(10)      default 0  not null,
  fileType              varchar(255) default '' not null,
  fileHash              varchar(255) default '' not null,
  uploadTime            int(10)      default 0  not null,
  userID                int(10)                 null,
  username              varchar(255)            not null,
  languageID            int(10)                 null,
  isMultilingual        tinyint(1)   default 0  not null,
  isImage               tinyint(1)   default 0  not null,
  width                 smallint(5)  default 0  not null,
  height                smallint(5)  default 0  not null,
  tinyThumbnailType     varchar(255) default '' not null,
  tinyThumbnailSize     int(10)      default 0  not null,
  tinyThumbnailWidth    smallint(5)  default 0  not null,
  tinyThumbnailHeight   smallint(5)  default 0  not null,
  smallThumbnailType    varchar(255) default '' not null,
  smallThumbnailSize    int(10)      default 0  not null,
  smallThumbnailWidth   smallint(5)  default 0  not null,
  smallThumbnailHeight  smallint(5)  default 0  not null,
  mediumThumbnailType   varchar(255) default '' not null,
  mediumThumbnailSize   int(10)      default 0  not null,
  mediumThumbnailWidth  smallint(5)  default 0  not null,
  mediumThumbnailHeight smallint(5)  default 0  not null,
  largeThumbnailType    varchar(255) default '' not null,
  largeThumbnailSize    int(10)      default 0  not null,
  largeThumbnailWidth   smallint(5)  default 0  not null,
  largeThumbnailHeight  smallint(5)  default 0  not null,
  categoryID            int(10)                 null,
  captionEnableHtml     tinyint(1)   default 0  not null,
  downloads             int(10)      default 0  not null,
  lastDownloadTime      int(10)      default 0  not null,
  fileUpdateTime        int(10)      default 0  not null,
  constraint d65ad3d9c92fe6108e6b750e6e33f991_fk
    foreign key (categoryID) references wcf3_category (categoryID)
      on delete set null,
  constraint de5415a32115c34094bbcc8d7cd451e9_fk
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null,
  constraint fec6f1d9fd21cc0cb0f0086ce8f43282_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_article_content
(
  articleContentID   int(10) auto_increment
        primary key,
  articleID          int(10)                 not null,
  languageID         int(10)                 null,
  title              varchar(255)            not null,
  teaser             text                    null,
  content            mediumtext              null,
  imageID            int(10)                 null,
  hasEmbeddedObjects tinyint(1)   default 0  not null,
  articleThreadID    int(10)                 null,
  teaserImageID      int(10)                 null,
  metaTitle          varchar(255) default '' not null,
  metaDescription    varchar(255) default '' not null,
  comments           smallint(5)  default 0  not null,
  constraint articleID
    unique (articleID, languageID),
  constraint `0da93b7d8339498cc97b34def54b3c7e_fk`
    foreign key (articleID) references wcf3_article (articleID)
      on delete cascade,
  constraint `18821b3742942a7926f6216319ccca78_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null,
  constraint `4bb7674cd71efe1988d7eca1e30c839a_fk`
    foreign key (articleThreadID) references wbb3_thread (threadID)
      on delete set null,
  constraint a9cb79c86715ec1c367d67f620c41eb7_fk
    foreign key (imageID) references wcf3_media (mediaID)
      on delete set null,
  constraint d1c2ea0f948547318349ec8dcb8ca95b_fk
    foreign key (teaserImageID) references wcf3_media (mediaID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_box_content
(
  boxContentID       int(10) auto_increment
        primary key,
  boxID              int(10)              not null,
  languageID         int(10)              null,
  title              varchar(255)         not null,
  content            mediumtext           null,
  imageID            int(10)              null,
  hasEmbeddedObjects tinyint(1) default 0 not null,
  constraint boxID
    unique (boxID, languageID),
  constraint `788888deaa48ab881d8331bc2378299f_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade,
  constraint b3065d5a719fd18e831f585cc7608e13_fk
    foreign key (boxID) references wcf3_box (boxID)
      on delete cascade,
  constraint b6d6705a38f7677191f2f8bdd5a34cda_fk
    foreign key (imageID) references wcf3_media (mediaID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_media_content
(
  mediaID    int(10)                 not null,
  languageID int(10)                 null,
  title      varchar(255)            not null,
  caption    text                    null,
  altText    varchar(255) default '' not null,
  constraint mediaID
    unique (mediaID, languageID),
  constraint `1943d5cee575be09e9c58800775e16cd_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade,
  constraint eaeaf1962497016dfeeb4ba2f2f00651_fk
    foreign key (mediaID) references wcf3_media (mediaID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_moderation_queue
(
  queueID        int(10) auto_increment
        primary key,
  objectTypeID   int(10)               not null,
  objectID       int(10)               not null,
  containerID    int(10)     default 0 not null,
  userID         int(10)               null,
  time           int(10)     default 0 not null,
  assignedUserID int(10)               null,
  status         tinyint(1)  default 0 not null,
  comments       smallint(5) default 0 not null,
  lastChangeTime int(10)     default 0 not null,
  additionalData text                  null,
  constraint `7397d58fc8f3ef171c9a7c59993b3125_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `9772fcd9fa88808ec9d1cacff682fb80_fk`
    foreign key (assignedUserID) references wcf3_user (userID)
      on delete set null,
  constraint b73d78f7cd6fc9518e605a6dd8dfaee9_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index objectTypeAndID
  on wcf3_moderation_queue (objectTypeID, objectID);

create table wcf3_moderation_queue_to_user
(
  queueID    int(10)              not null,
  userID     int(10)              not null,
  isAffected tinyint(1) default 0 not null,
  constraint queue
    unique (queueID, userID),
  constraint `817934015affdc953af976f96a04f848_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `9e0567de012670eaf66ad18ea06b67c7_fk`
    foreign key (queueID) references wcf3_moderation_queue (queueID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index affected
  on wcf3_moderation_queue_to_user (queueID, userID, isAffected);

create table wcf3_modification_log
(
  logID          int(10) auto_increment
        primary key,
  objectTypeID   int(10)                 not null,
  objectID       int(10)                 not null,
  parentObjectID int(10)                 null,
  userID         int(10)                 null,
  username       varchar(255) default '' not null,
  time           int(10)      default 0  not null,
  action         varchar(80)             not null,
  additionalData mediumtext              null,
  hidden         tinyint(1)   default 1  not null,
  constraint `3fd4dd0e54a0ac40389c69e97e0c89ec_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint `4a96c2909ce1357e86f31b4f98a368dd_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeAndID
  on wcf3_modification_log (objectTypeID, objectID);

create table wcf3_notice_dismissed
(
  noticeID int(10) not null,
  userID   int(10) not null,
  primary key (noticeID, userID),
  constraint `4488da1f4013c87d6f6dd7f1716fd893_fk`
    foreign key (noticeID) references wcf3_notice (noticeID)
      on delete cascade,
  constraint b853d8288b443ad926d416ef468dc032_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_oauth_client
(
  clientID             int(10) auto_increment
        primary key,
  identifier           varchar(80)             not null,
  name                 varchar(181)            not null,
  description          text                    not null,
  vendor               varchar(255)            not null,
  website              varchar(255)            not null,
  clientSecret         varchar(80)             not null,
  redirectUri          text                    not null,
  grantTypes           varchar(80)             not null,
  userID               int(10)                 null,
  scope                mediumtext              null,
  isDisabled           tinyint(1)   default 0  not null,
  logo                 int(10)                 null,
  legalNotice          varchar(255)            null,
  privacyPolicy        varchar(255)            null,
  authorizedUserGroups varchar(255) default '' not null,
  constraint identifier
    unique (identifier),
  constraint `8d5755af931c90b8073f782526d12cbc_fk`
    foreign key (logo) references wcf3_media (mediaID)
      on delete set null,
  constraint eb7f8a9b3362f57a1c6194586bbe5a4b_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_oauth_access_token
(
  accessToken varchar(40) not null
    primary key,
  clientID    int(10)     not null,
  userID      int(10)     null,
  expires     int(5)      not null,
  scope       mediumtext  null,
  constraint `8463b106f6e7125f631bf9f62c2fba36_fk`
    foreign key (clientID) references wcf3_oauth_client (clientID)
      on delete cascade,
  constraint a0d2b30f7aab0263deaf2d0fe316395f_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index expires
  on wcf3_oauth_access_token (expires);

create table wcf3_oauth_approval
(
  clientID int(10)    not null,
  userID   int(10)    not null,
  time     int(5)     not null,
  scope    mediumtext not null,
  constraint clientID
    unique (clientID, userID),
  constraint `165ac07f62657b1e87de533b737e7641_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `426446a466290bd704725cd6b71d8178_fk`
    foreign key (clientID) references wcf3_oauth_client (clientID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_oauth_authorization_code
(
  authorizationCode varchar(40) not null
    primary key,
  clientID          int(10)     not null,
  userID            int(10)     null,
  redirectUri       text        null,
  expires           int(5)      not null,
  scope             mediumtext  null,
  idToken           text        null,
  constraint `9776a0386a838f9c0b40a6a9bd540d22_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint c991b3207b22862491bfd4a3901e5663_fk
    foreign key (clientID) references wcf3_oauth_client (clientID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index expires
  on wcf3_oauth_authorization_code (expires);

create index isDisabled
  on wcf3_oauth_client (isDisabled);

create table wcf3_oauth_refresh_token
(
  refreshToken varchar(40) not null,
  clientID     int(10)     not null,
  userID       int(10)     null,
  expires      int(5)      not null,
  scope        mediumtext  null,
  tokenID      int(10) auto_increment
        primary key,
  constraint refreshToken
    unique (refreshToken),
  constraint `62c65f620b1a6418eda73cf282b3c975_fk`
    foreign key (clientID) references wcf3_oauth_client (clientID)
      on delete cascade,
  constraint dd0ddfb7f8e121829dbd7e7fb9428a32_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index expires
  on wcf3_oauth_refresh_token (expires);

create table wcf3_package_installation_queue
(
  queueID       int(10) auto_increment
        primary key,
  parentQueueID int(10)                                 default 0         not null,
  processNo     int(10)                                 default 0         not null,
  userID        int(10)                                                   not null,
  package       varchar(255)                            default ''        not null,
  packageName   varchar(255)                            default ''        not null,
  packageID     int(10)                                                   null,
  archive       varchar(255)                            default ''        not null,
  action        enum ('install', 'update', 'uninstall') default 'install' not null,
  done          tinyint(1)                              default 0         not null,
  isApplication tinyint(1)                              default 0         not null,
  constraint `247e0de4f4d1c029ef43c17ec0ea9660_fk`
    foreign key (packageID) references wcf3_package (packageID)
      on delete set null,
  constraint `8eefe5be21931de7e94d1bde2d25d7f1_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_installation_form
(
  queueID  int(10)                not null,
  formName varchar(80) default '' not null,
  document text                   not null,
  constraint formDocument
    unique (queueID, formName),
  constraint `3fcda77f9cea748dd9744bbb8b200a8e_fk`
    foreign key (queueID) references wcf3_package_installation_queue (queueID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_package_installation_node
(
  queueID    int(10)                not null,
  processNo  int(10)     default 0  not null,
  sequenceNo smallint(4) default 0  not null,
  node       char(8)     default '' not null,
  parentNode char(8)     default '' not null,
  nodeType   varchar(255)           not null,
  nodeData   text                   not null,
  done       tinyint(1)  default 0  not null,
  constraint `9e0e08c54ae4a56abe57004e3ae00bff_fk`
    foreign key (queueID) references wcf3_package_installation_queue (queueID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_page_version
(
  versionID int(10) auto_increment
        primary key,
  objectID  int(10)      not null,
  userID    int(10)      null,
  username  varchar(100) not null,
  time      int(10)      not null,
  data      longblob     null,
  constraint `8376b886729c992fd508ae2af7807ae0_fk`
    foreign key (objectID) references wcf3_page (pageID)
      on delete cascade,
  constraint d69c32070b190f9e1a60048ca8d28d65_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
comment 'Version tracking for com.woltlab.wcf.page' collate = utf8mb4_unicode_ci;

create table wcf3_paid_subscription_user
(
  subscriptionUserID         int(10) auto_increment
        primary key,
  subscriptionID             int(10)              not null,
  userID                     int(10)              not null,
  startDate                  int(10)    default 0 not null,
  endDate                    int(10)    default 0 not null,
  isActive                   tinyint(1) default 1 not null,
  sentExpirationNotification tinyint(1) default 0 not null,
  constraint subscriptionID
    unique (subscriptionID, userID),
  constraint `26b9e995f4b638eca3439cb30a8bf345_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `7324aacb48f83dfb4db29053262737dc_fk`
    foreign key (subscriptionID) references wcf3_paid_subscription (subscriptionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_paid_subscription_transaction_log
(
  logID                     int(10) auto_increment
        primary key,
  subscriptionUserID        int(10)                 null,
  userID                    int(10)                 null,
  subscriptionID            int(10)                 null,
  paymentMethodObjectTypeID int(10)                 not null,
  logTime                   int(10)      default 0  not null,
  transactionID             varchar(255) default '' not null,
  transactionDetails        mediumtext              null,
  logMessage                varchar(255) default '' not null,
  constraint `21f4d25b3de9b9788576848bf5fd6633_fk`
    foreign key (subscriptionID) references wcf3_paid_subscription (subscriptionID)
      on delete set null,
  constraint b1901749a3d6c7e40c64a66f2d24adcc_fk
    foreign key (userID) references wcf3_user (userID)
      on delete set null,
  constraint c01e7d0326f54af25bacb566cf470909_fk
    foreign key (subscriptionUserID) references wcf3_paid_subscription_user (subscriptionUserID)
      on delete set null,
  constraint d1ce89a89b3cc00d11c25a2541290cf7_fk
    foreign key (paymentMethodObjectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index isActive
  on wcf3_paid_subscription_user (isActive);

create table wcf3_poll_option_vote
(
  pollID   int(10) not null,
  optionID int(10) not null,
  userID   int(10) not null,
  constraint vote
    unique (pollID, optionID, userID),
  constraint `54882e6c647c5f5202a5993b5b9e714c_fk`
    foreign key (optionID) references wcf3_poll_option (optionID)
      on delete cascade,
  constraint `9f7319c9281f486bce095990155d3ed2_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint a35da988c707ef20fc83c13a67606c66_fk
    foreign key (pollID) references wcf3_poll (pollID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index optionID
  on wcf3_poll_option_vote (optionID, userID);

create table wcf3_search
(
  searchID   int(10) auto_increment
        primary key,
  userID     int(10)                 null,
  searchData mediumtext              not null,
  searchTime int(10)      default 0  not null,
  searchType varchar(255) default '' not null,
  searchHash char(40)     default '' not null,
  constraint `49247e648f987b37c674003bb2313cb8_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index searchHash
  on wcf3_search (searchHash);

create table wcf3_service_worker
(
  workerID        int(10) auto_increment
        primary key,
  userID          int(10)     not null,
  endpoint        text        null,
  publicKey       varchar(88) not null,
  authToken       varchar(24) not null,
  contentEncoding varchar(40) not null,
  constraint `5a7e82162df9b65a1a7a437af0543408_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index userID
  on wcf3_service_worker (userID);

create table wcf3_session
(
  sessionID          char(40)                not null
    primary key,
  userID             int(10)                 null,
  ipAddress          varchar(39)  default '' not null,
  userAgent          varchar(191) default '' not null,
  lastActivityTime   int(10)      default 0  not null,
  requestURI         varchar(255) default '' not null,
  requestMethod      varchar(7)   default '' not null,
  pageID             int(10)                 null,
  pageObjectID       int(10)                 null,
  parentPageID       int(10)                 null,
  parentPageObjectID int(10)                 null,
  spiderIdentifier   varchar(191)            null,
  constraint uniqueUserID
    unique (userID),
  constraint `2ce927d212fbfba29d941fc4d95e0805_fk`
    foreign key (parentPageID) references wcf3_page (pageID)
      on delete set null,
  constraint `718faf24b554bdebf882eabbfde393c8_fk`
    foreign key (pageID) references wcf3_page (pageID)
      on delete set null,
  constraint c03f0fc8d011c82bca2b5774ffc194b3_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index packageID
  on wcf3_session (lastActivityTime, spiderIdentifier);

create index pageID
  on wcf3_session (pageID, pageObjectID);

create index parentPageID
  on wcf3_session (parentPageID, parentPageObjectID);

create table wcf3_tracked_visit
(
  objectTypeID int(10)           not null,
  objectID     int(10)           not null,
  userID       int(10)           not null,
  visitTime    int(10) default 0 not null,
  constraint userID_objectTypeID_objectID
    unique (userID, objectTypeID, objectID),
  constraint `1e526aeafe9221b573b4fb38adf8a9e0_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `5acb3be1e3b6f00e1393dc40792f74ea_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index visitTime
  on wcf3_tracked_visit (visitTime);

create table wcf3_tracked_visit_type
(
  objectTypeID int(10)           not null,
  userID       int(10)           not null,
  visitTime    int(10) default 0 not null,
  constraint userID_objectTypeID
    unique (userID, objectTypeID),
  constraint `16a48aedab751f08a046eebbfd6c3a4e_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint b417c0282d3831b773cb2628e144a139_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index visitTime
  on wcf3_tracked_visit_type (visitTime);

create index activationCode
  on wcf3_user (activationCode);

create index activityPoints
  on wcf3_user (activityPoints);

create index authData
  on wcf3_user (authData);

create index email
  on wcf3_user (email);

create index galleryImages
  on wcf3_user (galleryImages);

create index galleryVideos
  on wcf3_user (galleryVideos);

create index likesReceived
  on wcf3_user (likesReceived);

create index marketplaceEntries
  on wcf3_user (marketplaceEntries);

create index registrationData
  on wcf3_user (registrationIpAddress, registrationDate);

create index registrationDate
  on wcf3_user (registrationDate);

create index styleID
  on wcf3_user (styleID);

create index trophyPoints
  on wcf3_user (trophyPoints);

create index wbbPosts
  on wcf3_user (wbbPosts);

create table wcf3_user_activity_event
(
  eventID        int(10) auto_increment
        primary key,
  objectTypeID   int(10) not null,
  objectID       int(10) not null,
  languageID     int(10) null,
  userID         int(10) not null,
  time           int(10) not null,
  additionalData text    null,
  constraint `1b873fe9035dc756546c8acd85d43e3e_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `294bb394ab97694da7992de5ae168417_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `4622056e702b4995737096c783aefd2d_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID
  on wcf3_user_activity_event (objectTypeID, objectID);

create index time
  on wcf3_user_activity_event (time);

create index userID
  on wcf3_user_activity_event (userID, time);

create table wcf3_user_activity_point
(
  userID         int(10)           not null,
  objectTypeID   int(10)           not null,
  activityPoints int(10) default 0 not null,
  items          int(10) default 0 not null,
  primary key (userID, objectTypeID),
  constraint `8d6c6f3cdb5c5dda4cc218dfcd555d57_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint cbcd2ea1b9c4c3325124711c6cf98471_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID
  on wcf3_user_activity_point (objectTypeID);

create table wcf3_user_authentication_failure
(
  failureID       int(10) auto_increment
        primary key,
  environment     enum ('user', 'admin') default 'user' not null,
  userID          int(10)                               null,
  username        varchar(255)           default ''     not null,
  time            int(10)                default 0      not null,
  ipAddress       varchar(39)            default ''     not null,
  userAgent       varchar(255)           default ''     not null,
  validationError varchar(255)           default ''     not null,
  constraint `8b1323b8bce00491ed8fe16b24465296_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create index ipAddress
  on wcf3_user_authentication_failure (ipAddress, time);

create index time
  on wcf3_user_authentication_failure (time);

create table wcf3_user_avatar
(
  avatarID        int(10) auto_increment
        primary key,
  avatarName      varchar(255) default '' not null,
  avatarExtension varchar(7)   default '' not null,
  width           smallint(5)  default 0  not null,
  height          smallint(5)  default 0  not null,
  userID          int(10)                 null,
  fileHash        varchar(40)  default '' not null,
  hasWebP         tinyint(1)   default 0  not null,
  constraint `80f5b0a1e4f7285c2fd6386bd3b7f529_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

alter table wcf3_user
  add constraint `6bdc7f5454578486b6e6772299e82b56_fk`
  foreign key (avatarID) references wcf3_user_avatar (avatarID)
  on delete set null;

create table wcf3_user_collapsible_content
(
  objectTypeID int(10)      not null,
  objectID     varchar(191) not null,
  userID       int(10)      not null,
  constraint objectTypeID
    unique (objectTypeID, objectID, userID),
  constraint `3c53e05e3dfd5444a6fd6f7e2a825752_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint e5b10afa3aac42f1b0a89d50760bce22_fk
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_follow
(
  followID     int(10) auto_increment
        primary key,
  userID       int(10)           not null,
  followUserID int(10)           not null,
  time         int(10) default 0 not null,
  constraint userID
    unique (userID, followUserID),
  constraint `26636f4cd26e53d555938fa8b564d72a_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `42c0fe8ef6ece15c359dcaf62f8e85a6_fk`
    foreign key (followUserID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_ignore
(
  ignoreID     int(10) auto_increment
        primary key,
  userID       int(10)              not null,
  ignoreUserID int(10)              not null,
  time         int(10)    default 0 not null,
  type         tinyint(1) default 1 not null,
  constraint userID
    unique (userID, ignoreUserID),
  constraint `2ae8678467a8d83e70355c4672383b4d_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `7814e34e5a8b219e911ad6c88aad8327_fk`
    foreign key (ignoreUserID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_infraction_warning
(
  userWarningID int(10) auto_increment
        primary key,
  objectID      int(10)                 null,
  objectTypeID  int(10)                 null,
  userID        int(10)                 not null,
  judgeID       int(10)                 null,
  warningID     int(10)                 null,
  time          int(10)      default 0  not null,
  title         varchar(255) default '' not null,
  points        mediumint(7) default 0  not null,
  expires       int(10)      default 0  not null,
  reason        mediumtext              null,
  revoked       tinyint(1)   default 0  not null,
  revoker       int(10)                 null,
  constraint `20118b48d21d21529cdfcc553ab35756_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `22ac8ec96a08d7047e4d794f3bab62f1_fk`
    foreign key (warningID) references wcf3_infraction_warning (warningID)
      on delete set null,
  constraint `851938726bec53eb3694fc0e75b76000_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint a9b25264fa794f1cd42a1724ec3ea9a0_fk
    foreign key (judgeID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_infraction_suspension
(
  userSuspensionID int(10) auto_increment
        primary key,
  userID           int(10)    default 0 not null,
  suspensionID     int(10)    default 0 not null,
  time             int(10)    default 0 not null,
  expires          int(10)    default 0 not null,
  revoked          tinyint(1) default 0 not null,
  revoker          int(10)              null,
  warningID        int(10)              null,
  constraint `938352c0e448f8478cc3e2aae143a31d_fk`
    foreign key (warningID) references wcf3_user_infraction_warning (userWarningID)
      on delete set null,
  constraint bccdf6a4313b5599567b63c4eabeb2f4_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint ddfec82e72d07021440ee20e24ee8588_fk
    foreign key (suspensionID) references wcf3_infraction_suspension (suspensionID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index suspensionID
  on wcf3_user_infraction_suspension (suspensionID);

create index userID
  on wcf3_user_infraction_suspension (userID);

create index judgeID
  on wcf3_user_infraction_warning (judgeID);

create index objectTypeID
  on wcf3_user_infraction_warning (objectTypeID, objectID);

create index warningID
  on wcf3_user_infraction_warning (warningID);

create table wcf3_user_iplog_all_user
(
  logID         int(10) auto_increment
        primary key,
  IPv4          varchar(39)  null,
  IPv6          varchar(39)  null,
  userAgent     varchar(255) not null,
  host          varchar(255) not null,
  language      varchar(255) null,
  userID        int          null,
  username      varchar(255) not null,
  lastCheckTime int          not null,
  firstLog      int          not null,
  constraint ipv4_ipv6_userID
    unique (IPv4, IPv6, userID),
  constraint `5135d5e979837c34ff389f656fa5844b_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index lastCheckTime
  on wcf3_user_iplog_all_user (lastCheckTime);

create table wcf3_user_iplog_double_accounts
(
  doubleAccountID int(10) auto_increment
        primary key,
  IPv4            varchar(39)          null,
  IPv6            varchar(39)          null,
  userAgent       varchar(255)         not null,
  host            varchar(255)         not null,
  userID          int                  null,
  username        varchar(255)         null,
  doubleUserID    int                  null,
  doubleUsername  varchar(255)         null,
  doubleUserAgent varchar(255)         not null,
  doubleHost      varchar(255)         not null,
  cookie          tinyint(1) default 0 not null,
  lastCheckTime   int                  not null,
  firstLog        int                  not null,
  disabled        tinyint(1) default 0 not null,
  constraint ipv4_ipv6_userID_doubleUserID_cookie
    unique (IPv4, IPv6, userID, doubleUserID, cookie),
  constraint `14bd7bd312528e74de2755a8c0d72408_fk`
    foreign key (doubleUserID) references wcf3_user (userID)
      on delete set null,
  constraint `5d572b6a7fdc8d2fa53399917c605708_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create table wcf3_user_multifactor
(
  setupID      int(10) auto_increment
        primary key,
  userID       int(10) not null,
  objectTypeID int(10) not null,
  constraint `6a26c0e2b49ec91a09d41b9a316aedfa`
    unique (userID, objectTypeID),
  constraint `6a26c0e2b49ec91a09d41b9a316aedfa_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `8c7ae8afb2baa8033c4f29cd147708c6_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_multifactor_backup
(
  setupID    int(10)      not null,
  identifier varchar(191) not null,
  code       varchar(255) not null,
  createTime int(10)      not null,
  useTime    int(10)      null,
  constraint `2c11e7bc1a70909848c9d8e0ffe9c4c9`
    unique (setupID, identifier),
  constraint `2c11e7bc1a70909848c9d8e0ffe9c4c9_fk`
    foreign key (setupID) references wcf3_user_multifactor (setupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_multifactor_email
(
  setupID    int(10)      not null,
  code       varchar(191) not null,
  createTime int(10)      not null,
  constraint `6b4296ec5476906ed53f38002d4328ee`
    unique (setupID, code),
  constraint `6b4296ec5476906ed53f38002d4328ee_fk`
    foreign key (setupID) references wcf3_user_multifactor (setupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_multifactor_totp
(
  setupID    int(10)        not null,
  deviceID   varchar(191)   not null,
  deviceName varchar(255)   not null,
  secret     varbinary(255) not null,
  minCounter int(10)        not null,
  createTime int(10)        not null,
  useTime    int(10)        null,
  constraint fc650547a68356972cf2f1a433a573a9
    unique (setupID, deviceID),
  constraint fc650547a68356972cf2f1a433a573a9_fk
    foreign key (setupID) references wcf3_user_multifactor (setupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_notification
(
  notificationID      int(10) auto_increment
        primary key,
  packageID           int(10)                not null,
  eventID             int(10)                not null,
  objectID            int(10)     default 0  not null,
  baseObjectID        int(10)     default 0  not null,
  eventHash           varchar(40) default '' not null,
  authorID            int(10)                null,
  timesTriggered      int(10)     default 0  not null,
  guestTimesTriggered int(10)     default 0  not null,
  userID              int(10)                not null,
  time                int(10)     default 0  not null,
  mailNotified        tinyint(1)  default 0  not null,
  confirmTime         int(10)     default 0  not null,
  additionalData      text                   null,
  constraint `1b67fa20a2d6f23c38ee554f5dc77e67_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `9f7a69bc62f6f36fcf7bc10ac1363c4f_fk`
    foreign key (eventID) references wcf3_user_notification_event (eventID)
      on delete cascade,
  constraint c7980d604fcb5d4f5b9e98b1688cfb45_fk
    foreign key (authorID) references wcf3_user (userID)
      on delete set null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_service_worker_notification
(
  notificationID int(10) not null,
  workerID       int(10) not null,
  time           int(10) not null,
  constraint job
    unique (notificationID, workerID),
  constraint a3fd0f457ee8b0f2369d9d623da4b787_fk
    foreign key (workerID) references wcf3_service_worker (workerID)
      on delete cascade,
  constraint e1192008627b822d6276874673319f2b_fk
    foreign key (notificationID) references wcf3_user_notification (notificationID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci
    row_format = DYNAMIC;

create index time
  on wcf3_service_worker_notification (time);

create index confirmTime
  on wcf3_user_notification (confirmTime);

create index userID
  on wcf3_user_notification (userID, eventID, objectID, confirmTime);

create index userID_2
  on wcf3_user_notification (userID, confirmTime);

create table wcf3_user_notification_author
(
  notificationID int(10)           not null,
  authorID       int(10)           null,
  time           int(10) default 0 not null,
  constraint notificationID
    unique (notificationID, authorID),
  constraint `1a4fb9e20b470dbeaceb5364846053b1_fk`
    foreign key (notificationID) references wcf3_user_notification (notificationID)
      on delete cascade,
  constraint b52d3ba601ac6f9b74b733ce1fa70194_fk
    foreign key (authorID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_notification_event_to_user
(
  userID               int(10)                                          not null,
  eventID              int(10)                                          not null,
  mailNotificationType enum ('none', 'instant', 'daily') default 'none' not null,
  constraint eventID
    unique (eventID, userID),
  constraint `65058fb809cfefc44960a02bbe766b5d_fk`
    foreign key (eventID) references wcf3_user_notification_event (eventID)
      on delete cascade,
  constraint b1c54f11fb4ff85cfd580637e466e196_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_object_watch
(
  watchID      int(10) auto_increment
        primary key,
  objectTypeID int(10)              not null,
  objectID     int(10)              not null,
  userID       int(10)              not null,
  notification tinyint(1) default 0 not null,
  constraint objectTypeID
    unique (objectTypeID, userID, objectID),
  constraint `2505c2416ab2ba172d16defc2a7386a6_fk`
    foreign key (objectTypeID) references wcf3_object_type (objectTypeID)
      on delete cascade,
  constraint `8cae6dddf6c5eb6a83ba1572556036cd_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index objectTypeID_2
  on wcf3_user_object_watch (objectTypeID, objectID);

create table wcf3_user_option_value
(
  userID       int(10)                         not null
        primary key,
  userOption1  text                            null,
  userOption2  char(10)   default '0000-00-00' not null,
  userOption3  tinyint(1) default 0            not null,
  userOption4  text                            null,
  userOption5  text                            null,
  userOption6  text                            null,
  userOption7  text                            null,
  userOption8  mediumtext                      null,
  userOption9  text                            null,
  userOption10 text                            null,
  userOption11 text                            null,
  userOption12 text                            null,
  userOption13 text                            null,
  userOption14 text                            null,
  userOption15 tinyint(1) default 0            not null,
  userOption16 text                            null,
  userOption17 tinyint(1) default 0            not null,
  userOption18 text                            null,
  userOption19 text                            null,
  userOption20 text                            null,
  userOption21 text                            null,
  userOption22 tinyint(1) default 0            not null,
  userOption23 text                            null,
  userOption24 text                            null,
  userOption25 text                            null,
  userOption26 text                            null,
  userOption27 text                            null,
  userOption28 text                            null,
  userOption29 tinyint(1) default 0            not null,
  userOption30 text                            null,
  userOption31 text                            null,
  userOption32 text                            null,
  userOption33 text                            null,
  userOption34 text                            null,
  userOption35 text                            null,
  userOption36 int(10)    default 0            not null,
  userOption37 int(10)    default 0            not null,
  userOption38 text                            null,
  userOption40 tinyint(1) default 0            not null,
  userOption41 text                            null,
  userOption42 text                            null,
  userOption43 text                            null,
  userOption44 mediumtext                      null,
  userOption45 tinyint(1) default 0            not null,
  userOption46 text                            null,
  constraint cfb77c6e290b713977fa5a5121c56231_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_profile_visitor
(
  visitorID int(10) auto_increment
        primary key,
  ownerID   int(10)           not null,
  userID    int(10)           not null,
  time      int(10) default 0 not null,
  constraint ownerID
    unique (ownerID, userID),
  constraint `130ba277e25d36e87a6b63279ccd4f7a_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `7d6e4f6b274907a9d8aebc91f3d637df_fk`
    foreign key (ownerID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index time
  on wcf3_user_profile_visitor (time);

create table wcf3_user_session
(
  sessionID        char(40)                not null
    primary key,
  userID           int(10)                 null,
  userAgent        varchar(255) default '' not null,
  ipAddress        varchar(39)  default '' null,
  creationTime     int(10)                 not null,
  lastActivityTime int(10)      default 0  not null,
  sessionVariables mediumblob              null,
  constraint d18fd908a5767414ad6dd2ad40f1f96a_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index `5ac96e373d48fb24fca6c33239782fb1`
  on wcf3_user_session (lastActivityTime);

create index d18fd908a5767414ad6dd2ad40f1f96a
  on wcf3_user_session (userID);

create table wcf3_user_special_trophy
(
  trophyID int(10) not null,
  userID   int(10) not null,
  constraint trophyID
    unique (trophyID, userID),
  constraint `1756d67b517f17cf2052d24a035d8c04_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint c996a27a2ddd796e56f14bfa09a6a85a_fk
    foreign key (trophyID) references wcf3_trophy (trophyID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_storage
(
  userID     int(10)                not null,
  field      varchar(80) default '' not null,
  fieldValue mediumtext             null,
  constraint userID
    unique (userID, field),
  constraint eacbc92a43a3d8479bc75643d3149550_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create index field
  on wcf3_user_storage (field);

create table wcf3_user_to_group
(
  userID  int(10) not null,
  groupID int(10) not null,
  constraint userID
    unique (userID, groupID),
  constraint `0ff1bbfb0bee8ad5f8c9eb192a0815bd_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `516e86ba10644d6bf790b7f8c007dcb0_fk`
    foreign key (groupID) references wcf3_user_group (groupID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_to_language
(
  userID     int(10) not null,
  languageID int(10) not null,
  constraint userID
    unique (userID, languageID),
  constraint `71db6f99652ebe63607927c010b3d9d9_fk`
    foreign key (userID) references wcf3_user (userID)
      on delete cascade,
  constraint `8d38e95e14ad3fab79a6d4885f17d813_fk`
    foreign key (languageID) references wcf3_language (languageID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_user_trophy
(
  userTrophyID         int(10) auto_increment
        primary key,
  trophyID             int(10)              not null,
  userID               int(10)              not null,
  time                 int(10)    default 0 not null,
  description          mediumtext           null,
  useCustomDescription tinyint(1) default 0 not null,
  trophyUseHtml        tinyint(1) default 0 not null,
  constraint `4b6d0d7d0239ac05334ee77d89928330_fk`
    foreign key (trophyID) references wcf3_trophy (trophyID)
      on delete cascade,
  constraint f129ebb89807ddf02515583057dc9f30_fk
    foreign key (userID) references wcf3_user (userID)
      on delete cascade
)
  collate = utf8mb4_unicode_ci;

create table wcf3_wsc_connect_login_attempts
(
  user     varchar(255) not null
    primary key,
  attempts tinyint(3)   not null,
  time     int(10)      not null
)
  collate = utf8mb4_unicode_ci;

create table wcf3_wsc_connect_notifications
(
  wscConnectNotificationID int(10) auto_increment
        primary key,
  data                     mediumtext not null
)
  collate = utf8mb4_unicode_ci;

create definer = forum@`%` view Mitgliedsnummern as
SELECT `forum`.`wcf1_user`.`username`                  AS `username`,
       `forum`.`wcf1_user`.`userID`                    AS `userID`,
       `forum`.`wcf1_user_option_value`.`userOption80` AS `userOption80`
FROM ((`forum`.`wcf1_user_option_value` JOIN `forum`.`wcf1_user`) JOIN `forum`.`wcf1_user_to_groups`)
WHERE `forum`.`wcf1_user`.`userID` = `forum`.`wcf1_user_option_value`.`userID`
  AND `forum`.`wcf1_user_to_groups`.`userID` = `forum`.`wcf1_user`.`userID`
  AND `forum`.`wcf1_user_to_groups`.`groupID` = 11;
