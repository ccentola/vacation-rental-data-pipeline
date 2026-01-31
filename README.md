# vacation-rental-data-pipeline

An end-to-end data pipeline built with dbt, Snowflake, and AWS. Implements a medallion architecture (bronze → silver → gold) for Airbnb listings, hosts, and booking data with incremental loading, data quality testing, and analytics-ready transformations.

## Architecture

```
Raw Data (Staging Layer)
        ↓
[BRONZE LAYER] ← First load from source systems
- Minimal transformations
- Incremental materialization
- Maintains data lineage
        ↓
[SILVER LAYER] ← Cleaned and standardized
- Data type casting
- Business logic application
- Unique key enforcement
- Incremental refresh
        ↓
[GOLD LAYER] ← Analytics-ready tables
- Fact and dimension tables
- Pre-calculated metrics
- Optimized for BI tools
```

### Data Entities

- **Listings**: Property inventory data (location, type, pricing, capacity)
- **Hosts**: Host profile information (response rates, ratings)
- **Bookings**: Reservation records with fees and transaction details

## Getting Started

### Prerequisites

- Python >=3.11
- [uv](https://docs.astral.sh/uv/) - for dependency management
- [dbt-core](https://docs.getdbt.com/docs/core/installation) >=1.11.2
- [dbt-snowflake](https://docs.getdbt.com/docs/core/dbt-cloud/snowflake-setup) >=1.11.1
- Snowflake account with AIRBNB_DEMO database and staging schema

### Installation

1. Clone the repository and navigate to the project:
   ```bash
   git clone <repo-url>
   cd airbnb-data
   ```

2. Install dependencies using uv:
   ```bash
   uv sync
   ```

3. Configure Snowflake connection by updating `airbnb_mds_project/profiles.yml`:
   ```yaml
   airbnb_mds_project:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: [your-account-id]
         user: [your-username]
         password: [your-password]
         role: [your-role]
         database: AIRBNB_DEMO
         schema: [dbt_schema_name]
         threads: 4
         client_session_keep_alive: False
   ```
   
   See `example_profiles.yml` for the expected structure. Keep credentials out of version control.

### Running the Pipeline

```bash
cd airbnb_mds_project

# Run all dbt models
dbt run

# Run and test
dbt run --select state:modified+

# Run specific layer
dbt run --select bronze
dbt run --select silver
dbt run --select gold

# Run data quality tests
dbt test

# Generate documentation and lineage graph
dbt docs generate
dbt docs serve
```

## Project Structure

```
airbnb_mds_project/
├── models/                    # dbt models organized by layer
│   ├── bronze/               # Raw data layer (minimal transformation)
│   │   ├── bronze_bookings.sql
│   │   ├── bronze_hosts.sql
│   │   └── bronze_listings.sql
│   ├── silver/               # Cleaned/standardized layer
│    ├── silver_bookings.sql
│   │   ├── silver_hosts.sql
│   │   └── silver_listings.sql
│   ├── gold/                 # Analytics-ready layer
│   │   ├── fact.sql          # Central fact table with joins
│   │   ├── obt.sql           # One Big Table for analytics
│   │   └── ephemeral/        # Temporary models for fact building
│   └── properties.yml        # Model configurations and tests
├── macros/                   # Reusable SQL logic
│   ├── generate_schema_name.sql  # Custom schema naming
│   ├── multiply.sql          # Example calculation macro
│   ├── tag.sql               # Data tagging/classification
│   └── trimmer.sql           # String trimming utility
├── tests/                    # dbt tests (data quality)
│   └── source_tests.sql      # Source table validation
├── analyses/                 # Ad-hoc SQL analysis
│   ├── if_else.sql
│   └── loop.sql
├── seeds/                    # Static CSV data loads
├── snapshots/                # Slowly changing dimension tracking
│   ├── dim_bookings.yml
│   ├── dim_hosts.yml
│   └── dim_listings.yml
├── dbt_project.yml           # Project configuration
├── profiles.yml              # Snowflake connection config
└── README.md
```

## Key Design Decisions

### 1. **Medallion Architecture**
- **Why**: Separates concerns, enables incremental transformations, and makes data lineage transparent
- **Implementation**: 
  - Bronze layer pulls directly from staging with `SELECT *`
  - Silver adds business logic, type casting, and deduplication
  - Gold creates analytics tables (facts/dimensions)

### 2. **Incremental Materialization**
- * Cost-effective in cloud warehouses, faster runs, only processes new data
- **Implementation**:
Medallion Architecture

Separates raw, cleaned, and analytics-ready data layers. Bronze pulls directly from source with minimal transformation, silver applies business logic and data quality rules, and gold provides analytics-optimized tables. This makes data lineage clear and enables independent testing at each stage.

- **Benefit**: Bronze layer uses `CREATED_AT` to track new records, avoiding full table rescans

### Incremental Materialization

Tables are loaded incrementally using a timestamp field to track changes. Only new or modified records are processed on each run, reducing compute costs and execution time:

```sql
{{ config(materialized="incremental", unique_key="listing_id") }}

SELECT ... 
{% if is_incremental() %}
  WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }})
{% endif %}
```

### Ephemeral Models

Intermediate dimensional tables (dim_bookings, dim_hosts, dim_listings) are ephemeral, meaning they're compiled directly into the fact table without creating separate database objects. This reduces storage overhead and join complexity.

### Jinja Macros

Custom macros like `tag()` standardize data classification and casting, and the schema naming macro dynamically manages schema generation. This reduces duplication and makes business logic updates straightforward.

### Snowflake Configuration

Multi-threaded execution (4 threads) enables parallel model builds. Snowflake's native Jinja integration and excellent handling of incremental logic make it a good fit for this architecture.


## Key Models

### Bronze Layer
- **bronze_listings**: Raw listings data, incremental load
- **bronze_hosts**: Raw host data, incremental load
- **bronze_bookings**: Raw booking data, incremental load

### Silver Layer
- **silver_listings**: Typed and cleaned listings (`listing_id`, `property_type`, `price_per_night`)
- **silver_hosts**: Host profiles with response rates
- **silver_bookings**: Bookings with all fees calculated

### Gold Layer
- **fact.sql**: Central fact table joining bookings with host and listing dimensions
- **obt.sql**: One Big Table containing all relevant booking, host, and listing attributes
- *Models

**Bronze Layer:**
- `bronze_listings`, `bronze_hosts`, `bronze_bookings` - Raw data ingestion

**Silver Layer:**
- `silver_listings`, `silver_hosts`, `silver_bookings` - Type casting, business logic, and deduplication

**Gold Layer:**
- `fact.sql` - Central fact table joining bookings with host and listing dimensions
- `obt.sql` - One Big Table for analytics consumption
- `dim_bookings`, `dim_hosts`, `dim_listings` - Ephemeral dimensional tables


Source data validation ensures upstream data integrity before transformation.

## Performance Considerations

| Configuration | Decision | Rationale |
|---|---|---|
| Materialization | Incremental + Full refresh option | Balance speed and freshness |
| Threads | 4 parallel threads | Optimal for Snowflake execution |
| Unique Key | listing_id (silver), booking_id (facts) | Prevents duplicates on refresh |
| Ephemeral Models | Intermediate dimensions | Reduces unnecessary storage |

## Documentation & Lineage

Generate interactive dbt documentation:
```bash
dbt docs generate
dbt docs serve
```

This creates:
- **Data lineage graph**: Visual dependencies between models
- **Columnn-level documentation**: Descriptions of all fields
- **Test coverage**: Which models are tested

## Development Workflow

### Adding a New Model
1. Create SQL file in appropriate layer (`models/[bronze|silver|gold]/`)
2. Add configuration in `dbt_project.yml`
3. Reference upstream sources or models with `{{ source() }}` or `{{ ref() }}`
4.  tests and documentation to `properties.yml`
5. Test with `dbt run --select [model_name]`

### Running in Different Environments
```bash
dbt run --target dev   # Development
dbt run --target prod  # Production
```

## Lessons & Best Practices Demonstrated

- **Version Control**: All SQL, configs, and tests tracked in git
- **Incremental Loading**: Only processes changed data, reducing costs
- **Testing**: Data quality tests at bronze→silver→gold boundaries
- **Documentation**: Self-documenting models with dbt docs
- **Modularity**: Macros and ephemeral models reduce code duplication
- **Configuration Management**: Separates dev/prod environments
- **SQL Best Practices**: Proper aliasing, readable formatting, comment-driven approach

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Orchestration | dbt | Data transformation, testing, documentation |
| Warehouse | Snowflake | Cloud-native OLAP database |
| Cloud | AWS | Data storage, compute resources |
| Python | >=3.11 | Environment & dependency management |
| Version Control | Git | Infrastructure as code |

### Development Notes

- All SQL, configs, and tests are version-controlled
- Incremental loading minimizes compute costs by processing only changed data
- Data quality tests validate assumptions at each transformation layer
- dbt docs generate interactive lineage and model documentation
- Macros and ephemeral models reduce duplication across transformations
- Configuration separates dev and prod environments
- SQL follows dbt conventions: proper aliasing, readable formatting, clear ref/source usage

### To Add Snapshots

| Component | Technology |
|---|---|
| Build System | uv |
| Orchestration | dbt |
| Warehouse | Snowflake |
| Cloud | AWS |
| Python | >= 3.11

**Performance Issues**: Increase `threads` in profiles.yml or optimize SQL

## Contact & Questions

This project demonstrates production data engineering practices suitable for analytics engineer and data engineer roles. The codebase demonstrates:
- ELT pipeline design
- Cloud data warehouse optimization  
- Data modeling and architecture
- Modern data tooling (dbt, Snowflake)
- Testing and documentation practices

