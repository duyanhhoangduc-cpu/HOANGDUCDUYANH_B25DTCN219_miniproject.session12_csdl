create database social_network;
use social_network;

create table users (
    user_id int primary key auto_increment,
    username varchar(50) not null unique,
    password varchar(255) not null,
    email varchar(100) not null unique,
    created_at datetime default current_timestamp
);

create table posts (
    post_id int primary key auto_increment,
    user_id int,
    content text not null,
    created_at datetime default current_timestamp,
    constraint fk_posts_users
    foreign key (user_id)
    references users(user_id)
    on delete cascade
);

create table comments (
    comment_id int primary key auto_increment,
    post_id int,
    user_id int,
    content text not null,
    created_at datetime default current_timestamp,
    constraint fk_comments_posts
    foreign key (post_id)
    references posts(post_id)
    on delete cascade,
    constraint fk_comments_users
    foreign key (user_id)
    references users(user_id)
    on delete cascade
);

create table friends (
    user_id int,
    friend_id int,
    status varchar(20),
    primary key(user_id, friend_id),
    constraint chk_friend_status
    check(status in ('pending','accepted')),
    constraint chk_not_self_friend
    check(user_id <> friend_id),
    constraint fk_friends_user
    foreign key (user_id)
    references users(user_id)
    on delete cascade,
    constraint fk_friends_friend
    foreign key (friend_id)
    references users(user_id)
    on delete cascade
);

create table likes (
    user_id int,
    post_id int,
    primary key(user_id, post_id),
    constraint fk_likes_users
    foreign key (user_id)
    references users(user_id)
    on delete cascade,
    constraint fk_likes_posts
    foreign key (post_id)
    references posts(post_id)
    on delete cascade
);

create index idx_post_created_at
on posts(created_at);

create view vw_userinfo as
select 
    user_id,
    username,
    email,
    created_at
from users;

create view vw_poststatistics as
select 
    p.post_id,
    p.content,
    u.username,
    count(distinct l.user_id) as total_likes,
    count(distinct c.comment_id) as total_comments
from posts p
left join users u
on p.user_id = u.user_id
left join likes l
on p.post_id = l.post_id
left join comments c
on p.post_id = c.post_id
group by p.post_id, p.content, u.username;

delimiter //

create procedure registeruser(
    in p_username varchar(50),
    in p_password varchar(255),
    in p_email varchar(100)
)
begin
    declare v_count int;

    select count(*) into v_count
    from users
    where email = p_email;

    if v_count > 0 then
        select 'email đã được sử dụng' as message;
    else
        insert into users(username, password, email)
        values(p_username, p_password, p_email);

        select 'đăng ký thành công' as message;
    end if;
end //

create procedure createpost(
    in p_user_id int,
    in p_content text,
    out p_post_id int
)
begin
    insert into posts(user_id, content)
    values(p_user_id, p_content);

    set p_post_id = last_insert_id();
end //

create procedure getfriendlist(
    in p_user_id int,
    in p_limit int,
    in p_offset int
)
begin
    select 
        u.username,
        u.email
    from friends f
    join users u
    on f.friend_id = u.user_id
    where f.user_id = p_user_id
    and f.status = 'accepted'
    limit p_limit offset p_offset;
end //

delimiter ;

call registeruser('danh', '123456', 'danh@gmail.com');

call createpost(1, 'hello mọi người', @mai);
select @mai;

call getfriendlist(1, 5, 0);

-- dùng on delete cascade để tự động xóa dữ liệu liên quan khi user bị xóa
-- tạo view để ẩn password và hỗ trợ thống kê tương tác bài viết
-- dùng index idx_post_created_at để tăng tốc truy vấn newsfeed
-- procedure registeruser kiểm tra email trùng trước khi insert
-- procedure createpost dùng out để trả lại post_id vừa tạo
-- procedure getfriendlist hỗ trợ phân trang bằng limit và offset