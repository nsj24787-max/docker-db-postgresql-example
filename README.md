# docker-db-postgresql-example
# Docker PostgreSQL 개발 DB 환경

PostgreSQL 16을 Docker Compose로 실행하는 개발용 DB 환경입니다.

이 프로젝트는 로컬 개발 환경에서 PostgreSQL DB를 빠르게 생성하고, 초기 사용자 및 권한 설정을 자동으로 적용하기 위한 예제입니다.

## 구성 파일

```text
.
├── docker-compose.yml
├── .env
├── initdb/
│   └── create_user.sql
└── backup/
    └── .gitkeep
```

## docker-compose.yml 전체 구조

현재 `docker-compose.yml`은 다음과 같은 구조를 가집니다.

```yaml
services:
  pg_hgf_dev:
    image: postgres:16
    container_name: pg_hgf_dev
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pg_hgf_dev_data:/var/lib/postgresql/data
      - ./initdb:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 20
    networks:
      - net_hgf_dev
    ports:
      - "${POSTGRES_PORT}:5432"

volumes:
  pg_hgf_dev_data:

networks:
  net_hgf_dev:
    driver: bridge
```

## docker-compose.yml 요소 설명

### services

```yaml
services:
```

Docker Compose에서 실행할 컨테이너 서비스들을 정의하는 영역입니다.

이 프로젝트에서는 PostgreSQL 컨테이너 하나만 실행합니다.

---

### pg_hgf_dev

```yaml
pg_hgf_dev:
```

서비스 이름입니다.

Docker Compose 내부에서 이 컨테이너를 식별할 때 사용하는 이름입니다.

예를 들어 다른 컨테이너가 이 PostgreSQL 컨테이너에 접속한다면 host 주소로 `pg_hgf_dev`를 사용할 수 있습니다.

---

### image

```yaml
image: postgres:16
```

컨테이너를 만들 때 사용할 Docker 이미지를 지정합니다.

여기서는 공식 PostgreSQL 16 이미지를 사용합니다.

즉, 별도의 PostgreSQL 설치 없이 Docker가 `postgres:16` 이미지를 내려받아 DB 서버를 실행합니다.

---

### container_name

```yaml
container_name: pg_hgf_dev
```

생성될 컨테이너의 실제 이름을 지정합니다.

이 값을 지정하지 않으면 Docker Compose가 프로젝트명과 서비스명을 조합해서 자동으로 컨테이너 이름을 만듭니다.

현재는 컨테이너 이름을 고정했기 때문에 다음과 같은 명령어를 사용할 수 있습니다.

```bash
docker logs pg_hgf_dev
docker exec -it pg_hgf_dev psql -U postgres -d hgf_mes
```

---

### environment

```yaml
environment:
  POSTGRES_DB: ${POSTGRES_DB}
  POSTGRES_USER: ${POSTGRES_USER}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

PostgreSQL 컨테이너에 전달할 환경 변수입니다.

PostgreSQL 공식 이미지는 처음 실행될 때 아래 환경 변수를 사용해 초기 DB와 계정을 생성합니다.

| 변수명 | 의미 |
|---|---|
| `POSTGRES_DB` | 처음 생성할 기본 데이터베이스 이름 |
| `POSTGRES_USER` | PostgreSQL 슈퍼유저 계정 |
| `POSTGRES_PASSWORD` | PostgreSQL 슈퍼유저 비밀번호 |

`${POSTGRES_DB}` 같은 값은 `.env` 파일에서 읽어옵니다.

예시:

```env
POSTGRES_DB=hgf_mes
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_PORT=5432
```

즉, 실제 컨테이너에는 다음과 같이 적용됩니다.

```yaml
POSTGRES_DB: hgf_mes
POSTGRES_USER: postgres
POSTGRES_PASSWORD: postgres
```

---

### volumes

```yaml
volumes:
  - pg_hgf_dev_data:/var/lib/postgresql/data
  - ./initdb:/docker-entrypoint-initdb.d
```

컨테이너와 호스트 사이의 파일 또는 디렉터리 저장 방식을 정의합니다.

현재는 볼륨이 2개 설정되어 있습니다.

---

### pg_hgf_dev_data:/var/lib/postgresql/data

```yaml
- pg_hgf_dev_data:/var/lib/postgresql/data
```

PostgreSQL의 실제 데이터 파일을 Docker named volume에 저장합니다.

`/var/lib/postgresql/data`는 PostgreSQL 컨테이너 내부에서 DB 데이터가 저장되는 기본 경로입니다.

이 설정 덕분에 컨테이너를 삭제하거나 재생성해도 named volume이 남아 있으면 DB 데이터는 유지됩니다.

예를 들어 아래 명령어는 컨테이너만 제거하고 볼륨은 유지합니다.

```bash
docker compose down
```

따라서 DB 데이터도 유지됩니다.

반대로 아래 명령어는 볼륨까지 삭제합니다.

```bash
docker compose down -v
```

이 경우 DB 데이터도 삭제됩니다.

---

### ./initdb:/docker-entrypoint-initdb.d

```yaml
- ./initdb:/docker-entrypoint-initdb.d
```

로컬 프로젝트의 `./initdb` 폴더를 컨테이너 내부의 `/docker-entrypoint-initdb.d` 경로에 연결합니다.

PostgreSQL 공식 Docker 이미지는 DB 데이터 디렉터리가 처음 생성될 때 `/docker-entrypoint-initdb.d` 안의 `.sql`, `.sh` 파일을 자동 실행합니다.

이 프로젝트에서는 다음 파일이 자동 실행 대상입니다.

```text
initdb/create_user.sql
```

주의할 점은 이 초기화 SQL은 컨테이너가 실행될 때마다 실행되는 것이 아닙니다.

DB 볼륨이 비어 있어 PostgreSQL 데이터 디렉터리가 처음 생성될 때만 실행됩니다.

즉, 이미 `pg_hgf_dev_data` 볼륨이 생성된 상태라면 `create_user.sql`을 수정해도 자동으로 다시 실행되지 않습니다.

초기화 SQL을 다시 실행하려면 볼륨을 삭제한 후 다시 실행해야 합니다.

```bash
docker compose down -v
docker compose up -d
```

---

### healthcheck

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
  interval: 5s
  timeout: 3s
  retries: 20
```

컨테이너가 정상적으로 실행 중인지 확인하는 설정입니다.

단순히 컨테이너가 켜져 있는지 보는 것이 아니라, PostgreSQL이 실제로 접속 가능한 상태인지 검사합니다.

---

### healthcheck.test

```yaml
test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
```

상태 확인에 사용할 명령어입니다.

`pg_isready`는 PostgreSQL 서버가 접속 가능한 상태인지 확인하는 명령어입니다.

현재 설정은 `.env`의 `POSTGRES_USER`, `POSTGRES_DB` 값을 사용해서 DB 접속 가능 여부를 확인합니다.

예시로 `.env`가 다음과 같다면:

```env
POSTGRES_DB=hgf_mes
POSTGRES_USER=postgres
```

실제로는 아래와 비슷하게 실행됩니다.

```bash
pg_isready -U postgres -d hgf_mes
```

---

### healthcheck.interval

```yaml
interval: 5s
```

healthcheck를 몇 초마다 실행할지 정합니다.

현재는 5초마다 PostgreSQL 상태를 확인합니다.

---

### healthcheck.timeout

```yaml
timeout: 3s
```

healthcheck 명령어가 3초 안에 응답하지 않으면 실패로 간주합니다.

---

### healthcheck.retries

```yaml
retries: 20
```

healthcheck 실패를 몇 번까지 재시도할지 정합니다.

현재는 최대 20번까지 재시도합니다.

즉, PostgreSQL이 완전히 뜨는 데 시간이 조금 걸려도 바로 실패 처리하지 않고 기다릴 수 있습니다.

---

### networks

```yaml
networks:
  - net_hgf_dev
```

이 컨테이너가 사용할 Docker 네트워크를 지정합니다.

현재 PostgreSQL 컨테이너는 `net_hgf_dev` 네트워크에 연결됩니다.

같은 네트워크에 연결된 다른 컨테이너는 `pg_hgf_dev`라는 서비스 이름으로 이 DB에 접근할 수 있습니다.

예를 들어 같은 네트워크에 Django 컨테이너가 있다면 DB host를 다음처럼 설정할 수 있습니다.

```env
DB_HOST=pg_hgf_dev
DB_PORT=5432
```

---

### ports

```yaml
ports:
  - "${POSTGRES_PORT}:5432"
```

호스트 PC와 컨테이너의 포트를 연결합니다.

형식은 다음과 같습니다.

```text
호스트포트:컨테이너포트
```

현재 설정은 `.env`의 `POSTGRES_PORT` 값을 호스트 포트로 사용합니다.

예를 들어 `.env`가 다음과 같다면:

```env
POSTGRES_PORT=5432
```

실제 포트 매핑은 다음과 같습니다.

```yaml
ports:
  - "5432:5432"
```

의미는 다음과 같습니다.

| 구분 | 포트 | 의미 |
|---|---:|---|
| 호스트 포트 | 5432 | 내 PC에서 접속할 포트 |
| 컨테이너 포트 | 5432 | PostgreSQL 컨테이너 내부 포트 |

즉, DBeaver 같은 외부 DB 툴에서는 다음 정보로 접속할 수 있습니다.

```text
Host: localhost
Port: 5432
Database: hgf_mes
User: postgres
Password: postgres
```

만약 로컬 PC에 이미 PostgreSQL이 5432 포트를 사용 중이라면 `.env`에서 포트를 바꿀 수 있습니다.

```env
POSTGRES_PORT=5433
```

이 경우 DBeaver에서는 다음처럼 접속합니다.

```text
Host: localhost
Port: 5433
Database: hgf_mes
User: postgres
Password: postgres
```

단, 컨테이너 내부 PostgreSQL 포트는 여전히 5432입니다.

---

### volumes 최상위 항목

```yaml
volumes:
  pg_hgf_dev_data:
```

Docker named volume을 정의하는 영역입니다.

서비스 내부에서 사용한 `pg_hgf_dev_data` 볼륨을 실제 Docker 볼륨으로 생성합니다.

이 볼륨은 PostgreSQL 데이터 저장소로 사용됩니다.

볼륨 목록 확인:

```bash
docker volume ls
```

해당 볼륨 상세 확인:

```bash
docker volume inspect hgf_mes_pg_hgf_dev_data
```

볼륨 이름은 Docker Compose 프로젝트명에 따라 앞에 prefix가 붙을 수 있습니다.

예를 들어 프로젝트 폴더명이 `hgf_mes`라면 실제 볼륨 이름은 다음처럼 생성될 수 있습니다.

```text
hgf_mes_pg_hgf_dev_data
```

---

### networks 최상위 항목

```yaml
networks:
  net_hgf_dev:
    driver: bridge
```

Docker 네트워크를 정의하는 영역입니다.

---

### net_hgf_dev

```yaml
net_hgf_dev:
```

사용자 정의 Docker 네트워크 이름입니다.

같은 네트워크에 연결된 컨테이너들은 서로 서비스 이름으로 통신할 수 있습니다.

---

### driver: bridge

```yaml
driver: bridge
```

Docker의 기본 브리지 네트워크 드라이버를 사용한다는 뜻입니다.

일반적인 로컬 개발 환경에서는 `bridge`를 사용하면 충분합니다.

이 설정을 통해 컨테이너끼리 독립된 네트워크 안에서 통신할 수 있습니다.

## create_user.sql 설명

`initdb/create_user.sql`은 PostgreSQL 컨테이너가 처음 생성될 때 자동 실행되는 초기화 SQL입니다.

현재 SQL은 다음과 같습니다.

```sql
do $$
begin
    if not exists (select from pg_roles where rolname = 'gaon') then
        create role gaon login password 'gaon';
    end if;
end
$$;

do $$
begin
    if not exists (select from pg_roles where rolname = 'mes21') then
        create role mes21 login password 'mes7033';
    end if;
end
$$;

alter schema public owner to mes21;

grant usage, create on schema public to mes21;
grant usage on schema public to gaon;

grant connect on database hgf_mes to mes21;
grant connect on database hgf_mes to gaon;

grant select, insert, update, delete on all tables in schema public to mes21;
grant usage, select on all sequences in schema public to mes21;

alter default privileges in schema public grant select, insert, update, delete on tables to mes21;
alter default privileges in schema public grant usage, select on sequences to mes21;
```

## create_user.sql 요소 설명

### gaon 계정 생성

```sql
do $$
begin
    if not exists (select from pg_roles where rolname = 'gaon') then
        create role gaon login password 'gaon';
    end if;
end
$$;
```

`gaon`이라는 PostgreSQL 로그인 계정을 생성합니다.

이미 `gaon` 계정이 있으면 다시 생성하지 않습니다.

---

### mes21 계정 생성

```sql
do $$
begin
    if not exists (select from pg_roles where rolname = 'mes21') then
        create role mes21 login password 'mes7033';
    end if;
end
$$;
```

`mes21`이라는 PostgreSQL 로그인 계정을 생성합니다.

이미 `mes21` 계정이 있으면 다시 생성하지 않습니다.

---

### public 스키마 소유자 변경

```sql
alter schema public owner to mes21;
```

`public` 스키마의 소유자를 `mes21`로 변경합니다.

이후 `mes21` 계정이 `public` 스키마에 대해 더 강한 관리 권한을 가지게 됩니다.

---

### mes21 스키마 권한 부여

```sql
grant usage, create on schema public to mes21;
```

`mes21` 계정에 `public` 스키마 사용 권한과 객체 생성 권한을 부여합니다.

| 권한 | 의미 |
|---|---|
| `usage` | 스키마 내부 객체에 접근 가능 |
| `create` | 스키마 안에 테이블, 시퀀스 등 객체 생성 가능 |

---

### gaon 스키마 권한 부여

```sql
grant usage on schema public to gaon;
```

`gaon` 계정에 `public` 스키마 사용 권한을 부여합니다.

단, `create` 권한은 없으므로 `public` 스키마 안에 새 테이블을 만들 수는 없습니다.

---

### DB 접속 권한 부여

```sql
grant connect on database hgf_mes to mes21;
grant connect on database hgf_mes to gaon;
```

`mes21`, `gaon` 계정에 `hgf_mes` 데이터베이스 접속 권한을 부여합니다.

---

### 기존 테이블 권한 부여

```sql
grant select, insert, update, delete on all tables in schema public to mes21;
```

`public` 스키마에 이미 존재하는 모든 테이블에 대해 `mes21` 계정에 CRUD 권한을 부여합니다.

| 권한 | 의미 |
|---|---|
| `select` | 조회 |
| `insert` | 추가 |
| `update` | 수정 |
| `delete` | 삭제 |

주의할 점은 이 명령은 이미 존재하는 테이블에만 적용됩니다.

나중에 새로 생성되는 테이블에는 자동 적용되지 않습니다.

새로 생성되는 테이블의 기본 권한은 아래 `alter default privileges`에서 설정합니다.

---

### 기존 시퀀스 권한 부여

```sql
grant usage, select on all sequences in schema public to mes21;
```

`public` 스키마에 이미 존재하는 모든 시퀀스에 대해 `mes21` 계정에 사용 권한을 부여합니다.

PostgreSQL에서 `serial`, `bigserial`, identity column을 사용하는 테이블은 내부적으로 시퀀스를 사용합니다.

시퀀스 권한이 없으면 insert 시 자동 증가 값을 가져오는 과정에서 권한 오류가 발생할 수 있습니다.

---

### 향후 생성될 테이블 기본 권한 설정

```sql
alter default privileges in schema public grant select, insert, update, delete on tables to mes21;
```

앞으로 `public` 스키마에 새로 생성되는 테이블에 대해 `mes21` 계정에 기본 CRUD 권한을 부여합니다.

단, 중요한 점이 있습니다.

`alter default privileges`는 이 명령을 실행한 역할이 나중에 생성하는 객체에 대해서만 기본 권한을 적용합니다.

즉, 다른 계정이 테이블을 생성하면 기대한 권한이 적용되지 않을 수 있습니다.

---

### 향후 생성될 시퀀스 기본 권한 설정

```sql
alter default privileges in schema public grant usage, select on sequences to mes21;
```

앞으로 `public` 스키마에 새로 생성되는 시퀀스에 대해 `mes21` 계정에 기본 사용 권한을 부여합니다.

## 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성합니다.

```env
POSTGRES_DB=hgf_mes
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_PORT=5432
```

## 실행 방법

컨테이너 실행:

```bash
docker compose up -d
```

컨테이너 상태 확인:

```bash
docker compose ps
```

로그 확인:

```bash
docker logs pg_hgf_dev
```

DB 접속:

```bash
docker exec -it pg_hgf_dev psql -U postgres -d hgf_mes
```

DBeaver 접속 예시:

```text
Host: localhost
Port: 5432
Database: hgf_mes
User: postgres
Password: postgres
```

## 초기화 SQL 재실행 방법

`create_user.sql`은 DB 볼륨이 처음 생성될 때만 자동 실행됩니다.

이미 볼륨이 존재하는 상태에서 SQL을 수정했다면 자동으로 다시 적용되지 않습니다.

초기화 SQL을 다시 실행하려면 다음 명령어로 볼륨을 삭제한 뒤 다시 실행합니다.

```bash
docker compose down -v
docker compose up -d
```

주의: `docker compose down -v`는 PostgreSQL 데이터까지 모두 삭제합니다.

## 백업 파일 관리

`backup/` 폴더는 DB 백업 파일을 보관하기 위한 디렉터리입니다.

단, `.backup` 파일은 용량이 크거나 실제 DB 데이터가 포함될 수 있으므로 Git에 커밋하지 않습니다.

`.gitignore` 예시:

```gitignore
.env
backup/*.backup
```

빈 `backup/` 폴더를 Git에 유지하기 위해 `backup/.gitkeep` 파일을 사용합니다.

```bash
touch backup/.gitkeep
```

## 백업 파일 복원 예시

백업 파일을 컨테이너 내부로 복사합니다.

```bash
docker cp backup/hgf_mes.backup pg_hgf_dev:/tmp/hgf_mes.backup
```

백업을 복원합니다.

```bash
docker exec -it pg_hgf_dev pg_restore -U postgres -d hgf_mes --clean --if-exists /tmp/hgf_mes.backup
```

소유자 정보를 제외하고 복원하려면 다음 옵션을 사용할 수 있습니다.

```bash
docker exec -it pg_hgf_dev pg_restore -U postgres -d hgf_mes --clean --if-exists --no-owner /tmp/hgf_mes.backup
```

## 자주 사용하는 명령어

컨테이너 실행:

```bash
docker compose up -d
```

컨테이너 상태 확인:

```bash
docker compose ps
```

로그 확인:

```bash
docker logs pg_hgf_dev
```

DB 접속:

```bash
docker exec -it pg_hgf_dev psql -U postgres -d hgf_mes
```

컨테이너 중지:

```bash
docker compose down
```

컨테이너와 볼륨 전체 삭제:

```bash
docker compose down -v
```

볼륨 목록 확인:

```bash
docker volume ls
```

네트워크 목록 확인:

```bash
docker network ls
```

## 보안 주의

이 프로젝트는 로컬 개발 환경 구성을 위한 예제입니다.

`create_user.sql`에는 개발용 계정명과 비밀번호가 포함되어 있습니다.

공개 GitHub 저장소에 업로드하는 경우 실제 운영 계정, 운영 비밀번호, 고객사 데이터가 포함된 백업 파일을 커밋하지 않아야 합니다.

커밋하지 않는 것을 권장하는 항목은 다음과 같습니다.

- `.env`
- DB 백업 파일
- 운영 DB 계정 정보
- 운영 DB 비밀번호
- 실제 고객사 데이터가 포함된 dump 파일
