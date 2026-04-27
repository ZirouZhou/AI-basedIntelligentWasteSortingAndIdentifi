-- Chat module schema design for:
-- 20260419_ai_intelligent_waste_sorting_identification_app
-- MySQL 5.7, UTF-8

USE `20260419_ai_intelligent_waste_sorting_identification_app`;

-- 1) Conversation header (direct chat for now)
CREATE TABLE IF NOT EXISTS chat_conversations (
  id VARCHAR(64) PRIMARY KEY,
  conversation_type VARCHAR(16) NOT NULL DEFAULT 'direct',
  latest_message_id BIGINT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_conversations_updated (updated_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 2) Participants in each conversation
CREATE TABLE IF NOT EXISTS chat_conversation_participants (
  conversation_id VARCHAR(64) NOT NULL,
  user_id VARCHAR(32) NOT NULL,
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_read_message_id BIGINT NULL,
  last_read_at DATETIME NULL,
  PRIMARY KEY (conversation_id, user_id),
  INDEX idx_chat_participants_user (user_id),
  CONSTRAINT fk_chat_participants_conversation
    FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_chat_participants_user
    FOREIGN KEY (user_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 3) Message body
CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  conversation_id VARCHAR(64) NOT NULL,
  sender_id VARCHAR(32) NOT NULL,
  message_type VARCHAR(16) NOT NULL, -- text | image
  content MEDIUMTEXT NOT NULL,        -- text content or image payload/url
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_messages_conversation_id (conversation_id, id),
  CONSTRAINT fk_chat_messages_conversation
    FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_chat_messages_sender
    FOREIGN KEY (sender_id) REFERENCES app_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 4) Forum-chat integration prerequisite:
-- forum_posts.author_id is required so avatar click can resolve target user.
-- This project already auto-upgrades this column in backend startup logic.
