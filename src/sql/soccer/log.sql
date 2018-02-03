CREATE TABLE log
(
	  file_path text  NOT NULL,
	  sha256 text  NOT NULL,
	  create_file_user_name text NOT NULL,
	  file_name text  NOT NULL,
	  created_at timestamp with time zone NOT NULL,
	  updated_at timestamp with time zone NOT NULL,
	  PRIMARY KEY (file_path)
);
