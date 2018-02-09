CREATE TABLE file_property
(
  absolute_path text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  user_id integer  NOT NULL,
  byte_size bigint  NOT NULL,
  author_name text  NOT NULL,
  league_id integer  NOT NULL,
  sha256 text  NOT NULL,
  PRIMARY KEY (absolute_path)
);
