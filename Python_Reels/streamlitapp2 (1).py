import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import base64
#Insert Data
df = pd.read_excel("Reels.xlsx")
df_Platform = pd.read_excel("df_platform.xlsx")
df_full = df.merge(df_Platform, on="user_id")  
# Page Config
st.set_page_config(
    page_title="ReelPulse",
    page_icon="🎬",
    layout="wide"
)

st.markdown("""
<style>

/* 🔝 TOP Page */
.block-container {
    padding-top: 2.2rem;
    padding-bottom: 0rem;
}

/* 📏 spacing between elements */
div[data-testid="stVerticalBlock"] {
    gap: 0.2rem;
}

/* 🧾 Text reset */
h1, h2, h3, h4, p {
    margin-top: 0px !important;
    margin-bottom: 0px !important;
}

/* 📊 KPIs spacing */
[data-testid="column"] {
    padding: 1rem !important;
}

/* 🧱 App background */
.stApp {
    background-color: #FFFFFF;
}

/* 📂 Sidebar background */
[data-testid="stSidebar"] {
    background-color: #F7F8FC;
}

/* Sidebar text */
[data-testid="stSidebar"] * {
    color: #1C011B;
}

/* Sidebar labels (radio/menu) */
[data-testid="stSidebar"] label {
    font-size: 70px;
    font-weight: 1500;
    color: #1C011B;
}

/* 🔘 Buttons */
.stButton > button {
    background-color: #535D73;
    color: #C5C8D9;
    border-radius: 8px;
    padding: 0.3rem 0.6rem;
}

</style>
""", unsafe_allow_html=True)

def kpi_card(title, value, accent_color="#1877F2"):
    st.markdown(f"""
    <div style="
        background-color:#F7F8FC;
        padding:16px 10px;
        border-radius:12px;
        border: 1.5px solid {accent_color};
        box-shadow: 0px 2px 8px rgba(0,0,0,0.07);
        text-align:center;
        width: 85%;
        margin: auto;
    ">
        <h6 style="color:#535D73; margin-bottom:6px; font-size:13px; font-weight:600; letter-spacing:0.5px; line-height:1;">
            {title}
        </h6>
        <h4 style="color:{accent_color}; margin:0; font-size:26px; font-weight:700; line-height:1.2;">
            {value}
        </h4>
    </div>
    """, unsafe_allow_html=True)
# Sidebar Header
video_file = open("Pivotsvideio.mp4", "rb")
video_bytes = video_file.read()

video_base64 = base64.b64encode(video_bytes).decode()

st.sidebar.markdown(
    f"""
    <video autoplay loop muted playsinline width="100%">
        <source src="data:video/mp4;base64,{video_base64}" type="video/mp4">
    </video>
    """,
    unsafe_allow_html=True
)

#Chosice Dashboards

page = st.sidebar.radio(
    "Navigate to:",
    [
        "🏠 Overview",
        "📊 Who Are the Users?",
        "📱 How Do They Use Reels?",
        "🛒 Purchase Behavior",
        "🧠 Social & Psychological Impact"
    ]
)


# ==============================
# USERS DASHBOARD FUNCTION
# ==============================

def show_users_KPIs(filtered_df):
    total_users = len(filtered_df)

    if not filtered_df.empty:
        most_age = filtered_df["age_group"].value_counts().idxmax()
        daily_watch_hours = filtered_df["daily_watch_hours"].value_counts().idxmax()
    else:
        most_age = "N/A"
        daily_watch_hours = 0

    col1, col2, col3 = st.columns(3)

    with col1:
        kpi_card("Total Users", total_users, accent_color="#010101")       # TikTok

    with col2:
        kpi_card("Top Age Group", most_age, accent_color="#1877F2")        # Facebook

    with col3:
        kpi_card("Daily Watch Hours", daily_watch_hours, accent_color="#E1306C")  # Instagram

    st.markdown("<div style='height:20px'></div>", unsafe_allow_html=True)
def show_users_charts(filtered_df):

    border_style = """
        <style>
        div[data-testid="stVerticalBlockBorderWrapper"] {
            border: 1.5px solid #C5C8D9 !important;
            border-radius: 12px !important;
            background-color: #F7F8FC !important;
        }
        </style>
    """
    st.markdown(border_style, unsafe_allow_html=True)

    social_colors = ["#D94169", "#1877F2", "#E1306C", "#FF0000", "#FFFC00", "#25D366"]

    # ===== الصف الأول: Lollipop + Donut =====
    col1, col2 = st.columns(2, gap="medium")

    with col1:
        with st.container(border=True):
            region_count = filtered_df["region"].value_counts().reset_index()
            region_count.columns = ["Region", "Count"]

            fig1 = go.Figure()

            for i, row in region_count.iterrows():
                fig1.add_trace(go.Scatter(
                    x=[0, row["Count"]],
                    y=[row["Region"], row["Region"]],
                    mode="lines",
                    line=dict(color="#C5C8D9", width=2.5),
                    showlegend=False
                ))

            fig1.add_trace(go.Scatter(
                x=region_count["Count"],
                y=region_count["Region"],
                mode="markers+text",
                marker=dict(
                    size=16,
                    color=social_colors[:len(region_count)],
                    line=dict(color="white", width=2)
                ),
                text=region_count["Count"],
                textposition="middle right",
                textfont=dict(size=12, color="#002333"),
                showlegend=False
            ))

            fig1.update_layout(
                title=dict(text="Region Distribution", font=dict(size=14)),
                height=230,  # ← من 280
                margin=dict(t=40, b=20, l=10, r=55),
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                xaxis=dict(showgrid=True, gridcolor="#E0E3EF", title="Count", tickfont=dict(size=11)),
                yaxis=dict(showgrid=False, title="", tickfont=dict(size=11))
            )
            st.plotly_chart(fig1, use_container_width=True)

    with col2:
        with st.container(border=True):
            marital_count = filtered_df["marital_status"].value_counts().reset_index()
            marital_count.columns = ["Marital Status", "Count"]

            fig2 = px.pie(
                marital_count,
                names="Marital Status",
                values="Count",
                title="Marital Status Distribution",
                hole=0.5,
                color_discrete_sequence=["#D94169", "#1877F2", "#FF0000", "#FFFC00"]
            )
            fig2.update_traces(
                textinfo="percent+label",
                textfont=dict(size=12)
            )
            fig2.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(
                    text="Marital Status Distribution",
                    y=0.97, x=0.5,
                    xanchor="center",
                    yanchor="top",
                    font=dict(size=14)
                ),
                legend=dict(font=dict(size=11), orientation="v", x=1, y=0.5),
                height=230,  # ← من 280
                margin=dict(t=40, b=20, l=10, r=10)                                           # ← أصغر
            )
            st.plotly_chart(fig2, use_container_width=True)

    # ===== الصف التاني: Treemap + Bar =====
    col3, col4 = st.columns(2, gap="medium")

    with col3:
        with st.container(border=True):
            occupation_count = filtered_df["occupation"].value_counts().reset_index()
            occupation_count.columns = ["Occupation", "Count"]

            fig3 = px.treemap(
                occupation_count,
                path=["Occupation"],
                values="Count",
                color="Count",
                color_continuous_scale=["#AF1C80", "#145CBA", "#FF0000", "#FFFC00"],
                title="Occupation Breakdown"
            )
            fig3.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                coloraxis_showscale=False,
                title=dict(
                    text="Occupation Breakdown",
                    y=0.97, x=0.5,
                    xanchor="center",
                    yanchor="top",
                    font=dict(size=14)
                ),
                height=230,  # ← من 280
                margin=dict(t=40, b=20, l=10, r=10)                                           # ← أصغر
            )
            st.plotly_chart(fig3, use_container_width=True)

    with col4:
        with st.container(border=True):
            edu_count = filtered_df["education_level"].value_counts().reset_index()
            edu_count.columns = ["Education", "Count"]

            fig4 = px.bar(
                edu_count,
                x="Education",
                y="Count",
                title="Education Level",
                color="Education",
                text="Count",
                color_discrete_sequence=social_colors
            )
            fig4.update_layout(
                height=230,  # ← من 280
                margin=dict(t=40, b=20, l=10, r=10),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                title=dict(font=dict(size=14)),
                xaxis=dict(title="Education", tickfont=dict(size=11)),
                yaxis=dict(title="Count", tickfont=dict(size=11))
            )
            fig4.update_traces(
                textposition="outside",
                textfont=dict(size=11)
            )
            st.plotly_chart(fig4, use_container_width=True)

def show_users_dashboard():

    st.markdown("## 📊 Who Are the Users?")

    # Filters
    st.sidebar.subheader("🔽 Filters")

    gender = st.sidebar.multiselect(
        "Gender",
        options=df["gender"].unique(),
        default=[]
    )

    age_group = st.sidebar.multiselect(
        "Age Group",
        options=df["age_group"].unique(),
        default=[]
    )

    region = st.sidebar.multiselect(
        "Region",
        options=df["region"].unique(),
        default=[]
    )

    education = st.sidebar.multiselect(
        "Education Level",
        options=df["education_level"].unique(),
        default=[]
    )

    # Handle empty selection (important)
    if not gender:
        gender = df["gender"].unique()

    if not age_group:
        age_group = df["age_group"].unique()

    if not region:
        region = df["region"].unique()

    if not education:
        education = df["education_level"].unique()

    # Filtered Data
    filtered_df = df[
        (df["gender"].isin(gender)) &
        (df["age_group"].isin(age_group)) &
        (df["region"].isin(region)) &
        (df["education_level"].isin(education))
    ]
    
    show_users_KPIs(filtered_df)
    st.markdown("---")
    show_users_charts(filtered_df)


# ==============================
# Reels DASHBOARD FUNCTION
# ==============================

def show_reels_KPIs(filtered_df):

    if not filtered_df.empty:
        platform_count = filtered_df["primary_platform"].nunique()
        most_platform = filtered_df["primary_platform"].value_counts().idxmax()
        peak_time = filtered_df["peak_usage_time"].value_counts().idxmax()
    else:
        platform_count = 0
        most_platform = "N/A"
        peak_time = "N/A"

    col1, col2, col3 = st.columns(3, gap="large")

    with col1:
        kpi_card("Platform Count", platform_count, accent_color="#010101")
    with col2:
        kpi_card("Most Used Platform", most_platform, accent_color="#1877F2")
    with col3:
        kpi_card("Peak Usage Time", peak_time, accent_color="#E1306C")

    st.markdown("<div style='height:20px'></div>", unsafe_allow_html=True)


def show_reels_charts(filtered_df):

    border_style = """
        <style>
        div[data-testid="stVerticalBlockBorderWrapper"] {
            border: 1.5px solid #C5C8D9 !important;
            border-radius: 12px !important;
            background-color: #F7F8FC !important;
        }
        </style>
    """
    st.markdown(border_style, unsafe_allow_html=True)

    social_colors = ["#D94169", "#1877F2", "#540721", "#FF0000", "#FFFC00", "#25D366"]

    # ===== الصف الأول: Histogram + Lollipop =====
    col1, col2 = st.columns(2, gap="medium")

    with col1:
        with st.container(border=True):
            unique_users_df = filtered_df.drop_duplicates(subset=["user_id"])

            fig1 = px.histogram(
                unique_users_df,
                x="watch_intensity_score",
                title="Watch Intensity Score Distribution",
                color_discrete_sequence=["#D94169"]
            )
            fig1.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(text="Watch Intensity Score Distribution",
                           y=0.97, x=0.5, xanchor="center", yanchor="top", font=dict(size=14)),
                margin=dict(t=45, b=20, l=10, r=10),
                height=230
            )
            st.plotly_chart(fig1, use_container_width=True)

    with col2:
     with st.container(border=True):
        content_count = filtered_df["content_type"].value_counts().reset_index()
        content_count.columns = ["Content Type", "Count"]

        fig2 = px.bar(
            content_count,
            x="Count",
            y="Content Type",
            orientation="h",
            text="Count",
            title="Content Type Distribution",
            color="Content Type",
            color_discrete_sequence=social_colors
        )
        fig2.update_layout(
            title=dict(text="Content Type Distribution",
                       font=dict(size=14), y=0.97, x=0.5,
                       xanchor="center", yanchor="top"),
            height=250,
            margin=dict(t=45, b=20, l=10, r=55),
            showlegend=False,
            plot_bgcolor="#F7F8FC",
            paper_bgcolor="#F7F8FC",
            xaxis=dict(showgrid=True, gridcolor="#E0E3EF", title="Count", tickfont=dict(size=11)),
            yaxis=dict(showgrid=False, title="", tickfont=dict(size=11))
        )
        fig2.update_traces(textposition="outside", textfont=dict(size=11))
        st.plotly_chart(fig2, use_container_width=True)

    # ===== الصف التاني: Bar + Donut =====
    col3, col4 = st.columns(2, gap="medium")

    with col3:
        with st.container(border=True):
            peak_count = (
                filtered_df.groupby("peak_usage_time")["user_id"]
                .nunique()
                .reset_index()
            )
            peak_count.columns = ["Peak Time", "Count"]

            fig3 = px.bar(
                peak_count,
                x="Peak Time",
                y="Count",
                title="Peak Usage Time",
                color="Peak Time",
                text="Count",
                color_discrete_sequence=social_colors
            )
            fig3.update_layout(
                height=230,
                margin=dict(t=45, b=20, l=10, r=10),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                title=dict(font=dict(size=14), y=0.97, x=0.5,
                           xanchor="center", yanchor="top"),
                xaxis=dict(title="Peak Time", tickfont=dict(size=11)),
                yaxis=dict(title="Count", tickfont=dict(size=11))
            )
            fig3.update_traces(textposition="outside", textfont=dict(size=11))
            st.plotly_chart(fig3, use_container_width=True)

    with col4:
        with st.container(border=True):
            segment_count = (
                filtered_df.groupby("user_segment")["user_id"]
                .nunique()
                .reset_index()
            )
            segment_count.columns = ["User Segment", "Count"]

            fig4 = px.pie(
                segment_count,
                names="User Segment",
                values="Count",
                title="User Segment",
                hole=0.5,
                color_discrete_sequence=["#D94169", "#1877F2", "#E1306C"]
            )
            fig4.update_traces(
                textinfo="percent+label",
                textfont=dict(size=12)
            )
            fig4.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(text="User Segment", y=0.97, x=0.5,
                           xanchor="center", yanchor="top", font=dict(size=14)),
                legend=dict(font=dict(size=11), orientation="v", x=1, y=0.5),
                margin=dict(t=45, b=20, l=10, r=10),
                height=230
            )
            st.plotly_chart(fig4, use_container_width=True)

def show_reels_dashboard():

    st.markdown("## 📱 How Do They Use Reels?")

    # Filters
    st.sidebar.subheader("🔽 Filters")

    platform = st.sidebar.multiselect(
        "Primary Platform",
        options=df_full["primary_platform"].unique(),
        default=[]
    )

    age_group = st.sidebar.multiselect(
        "Age Group",
        options=df_full["age_group"].unique(),
        default=[]
    )

    content = st.sidebar.multiselect(
        "Content Type",
        options=df_full["content_type"].unique(),
        default=[]
    )

    segment = st.sidebar.multiselect(
        "User Segment",
        options=df_full["user_segment"].unique(),
        default=[]
    )

    # Handle empty selection
    if not platform:
        platform = df_full["primary_platform"].unique()
    if not age_group:
        age_group = df_full["age_group"].unique()
    if not content:
        content = df_full["content_type"].unique()
    if not segment:
        segment = df_full["user_segment"].unique()

    # Filtered Data
    filtered2_df = df_full[
        (df_full["primary_platform"].isin(platform)) &
        (df_full["age_group"].isin(age_group)) &
        (df_full["content_type"].isin(content)) &
        (df_full["user_segment"].isin(segment))
    ]

    show_reels_KPIs(filtered2_df)
    st.markdown("---")
    show_reels_charts(filtered2_df)          

# ==========================================
# Purches DASHBOARD SECTIONS
# ==========================================

def show_purchase_KPIs(filtered_df):

    total_users = filtered_df["user_id"].nunique()

    if not filtered_df.empty:
        buyers = filtered_df[
            filtered_df["purchased_from_video"].isin([
                "Once or twice",
                "Yes, often (easily influenced)"
            ])
        ]
        buyer_users = buyers["user_id"].nunique()
        conv_rate = (buyer_users / total_users * 100) if total_users > 0 else 0

        impulse_buyers = filtered_df[
            filtered_df["purchase_influence_level"] == "High influence (impulse)"
        ]["user_id"].nunique()

        top_reason = (
            filtered_df["purchase_reason"].value_counts().idxmax()
            if "purchase_reason" in filtered_df.columns
            else "N/A"
        )
    else:
        conv_rate = 0
        buyer_users = 0
        impulse_buyers = 0
        top_reason = "N/A"

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        kpi_card("Conversion Rate", f"{conv_rate:.1f}%", accent_color="#010101")
    with col2:
        kpi_card("Total Buyers", f"{buyer_users:,}", accent_color="#1877F2")
    with col3:
        kpi_card("Impulse Buyers", f"{impulse_buyers:,}", accent_color="#E1306C")
    with col4:
        kpi_card("Top Reason", top_reason, accent_color="#FF0000")

    st.markdown("<div style='height:20px'></div>", unsafe_allow_html=True)

def show_purchase_charts(filtered_df):

    border_style = """
        <style>
        div[data-testid="stVerticalBlockBorderWrapper"] {
            border: 1.5px solid #C5C8D9 !important;
            border-radius: 12px !important;
            background-color: #F7F8FC !important;
        }
        </style>
    """
    st.markdown(border_style, unsafe_allow_html=True)

    social_colors = ["#D94169","#FFFC00", "#1877F2", "#540721", "#FF0000",  "#25D366"]

    # ===== الصف الأول: Donut + Horizontal Bar =====
    col1, col2 = st.columns(2, gap="medium")

    with col1:
        with st.container(border=True):
            conversion = (
                filtered_df.groupby("purchased_from_video")["user_id"]
                .nunique()
                .reset_index()
            )
            conversion.columns = ["Status", "Users"]

            fig1 = px.pie(
                conversion,
                names="Status",
                values="Users",
                hole=0.6,
                title="Purchase Conversion (Users)",
                color_discrete_sequence=social_colors
            )
            fig1.update_traces(
                textinfo="percent+label",
                textfont=dict(size=12)
            )
            fig1.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(text="Purchase Conversion (Users)",
                           y=0.97, x=0.5, xanchor="center", yanchor="top",
                           font=dict(size=14)),
                legend=dict(font=dict(size=11), orientation="v", x=1, y=0.5),
                margin=dict(t=45, b=20, l=10, r=10),
                height=230
            )
            st.plotly_chart(fig1, use_container_width=True)

    with col2:
        with st.container(border=True):
            infl = (
                filtered_df.groupby("purchase_influence_level")["user_id"]
                .nunique()
                .reset_index()
            )
            infl.columns = ["Influence", "Users"]

            fig2 = px.bar(
                infl,
                x="Users",
                y="Influence",
                orientation="h",
                text="Users",
                title="Influence Level (Users)",
                color="Influence",
                color_discrete_sequence=social_colors
            )
            fig2.update_layout(
                height=230,
                margin=dict(t=45, b=20, l=10, r=55),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                title=dict(font=dict(size=14), y=0.97, x=0.5,
                           xanchor="center", yanchor="top"),
                xaxis=dict(showgrid=True, gridcolor="#E0E3EF",
                           title="Users", tickfont=dict(size=11)),
                yaxis=dict(showgrid=False, title="", tickfont=dict(size=11))
            )
            fig2.update_traces(textposition="outside", textfont=dict(size=11))
            st.plotly_chart(fig2, use_container_width=True)

    # ===== الصف التاني: Treemap + Bar =====
    col3, col4 = st.columns(2, gap="medium")

    with col3:
        with st.container(border=True):
            reasons = filtered_df[
                filtered_df["purchase_reason"] != "N/A – Never purchased"
            ]
            reason_count = (
                reasons.groupby("purchase_reason")["user_id"]
                .nunique()
                .reset_index()
            )
            reason_count.columns = ["Reason", "Users"]

            fig3 = px.treemap(
                reason_count,
                path=["Reason"],
                values="Users",
                title="Purchase Reasons (Users)",
                color="Users",
                color_continuous_scale=["#E1306C", "#FF0000", "#FFFC00", "#25D366"]
            )
            fig3.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                coloraxis_showscale=False,
                title=dict(text="Purchase Reasons (Users)",
                           y=0.97, x=0.5, xanchor="center", yanchor="top",
                           font=dict(size=14)),
                margin=dict(t=45, b=20, l=10, r=10),
                height=230
            )
            st.plotly_chart(fig3, use_container_width=True)

    with col4:
        with st.container(border=True):
            order = ["Always", "Usually", "Sometimes", "Rarely", "Never"]

            rew = (
                filtered_df.groupby("rewatched_before_purchase")["user_id"]
                .nunique()
                .reindex(order)
                .reset_index()
            )
            rew.columns = ["Rewatch", "Users"]

            fig4 = px.bar(
                rew,
                x="Rewatch",
                y="Users",
                text="Users",
                title="Rewatch Before Purchase (Users)",
                color="Rewatch",
                color_discrete_sequence=social_colors
            )
            fig4.update_layout(
                height=230,
                margin=dict(t=45, b=20, l=10, r=10),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                title=dict(font=dict(size=14), y=0.97, x=0.5,
                           xanchor="center", yanchor="top"),
                xaxis=dict(title="Rewatch", tickfont=dict(size=11)),
                yaxis=dict(title="Users", tickfont=dict(size=11))
            )
            fig4.update_traces(textposition="outside", textfont=dict(size=11))
            st.plotly_chart(fig4, use_container_width=True)

def show_purchase_dashboard():

    st.markdown("## 🛍️ Purchase Behavior Analysis")

    # =====================
    # FILTERS (same style)
    # =====================
    st.sidebar.subheader("🔽 Filters")

    platform = st.sidebar.multiselect(
        "Primary Platform",
        options=df_full["primary_platform"].unique(),
        default=[]
    )

    segment = st.sidebar.multiselect(
        "User Segment",
        options=df_full["user_segment"].unique(),
        default=[]
    )

    purchase = st.sidebar.multiselect(
        "Purchase Status",
        options=df_full["purchased_from_video"].unique(),
        default=[]
    )

    influence = st.sidebar.multiselect(
        "Influence Level",
        options=df_full["purchase_influence_level"].unique(),
        default=[]
    )

    # =====================
    # HANDLE EMPTY (IMPORTANT)
    # =====================
    if not platform:
        platform = df_full["primary_platform"].unique()
    if not segment:
        segment = df_full["user_segment"].unique()
    if not purchase:
        purchase = df_full["purchased_from_video"].unique()
    if not influence:
        influence = df_full["purchase_influence_level"].unique()

    # =====================
    # FILTER DATA
    # =====================
    filtered_df = df_full[
        (df_full["primary_platform"].isin(platform)) &
        (df_full["user_segment"].isin(segment)) &
        (df_full["purchased_from_video"].isin(purchase)) &
        (df_full["purchase_influence_level"].isin(influence))
    ]

    show_purchase_KPIs(filtered_df)
    st.markdown("---")
    show_purchase_charts(filtered_df)


# ==============================
# SOCIAL & PSYCHOLOGICAL DASHBOARD (UPDATED)
# ==============================
def show_impact_KPIs(filtered_df):

    if not filtered_df.empty:
        difficulty = (
            filtered_df.groupby("difficulty_closing_app")["user_id"]
            .nunique()
            .idxmax()
            if "difficulty_closing_app" in filtered_df.columns
            else "N/A"
        )
        prod_impact = (
            filtered_df.groupby("productivity_impact")["user_id"]
            .nunique()
            .idxmax()
            if "productivity_impact" in filtered_df.columns
            else "N/A"
        )
        sleep_imp = (
            filtered_df.groupby("sleep_impact")["user_id"]
            .nunique()
            .idxmax()
            if "sleep_impact" in filtered_df.columns
            else "N/A"
        )
    else:
        difficulty, prod_impact, sleep_imp = "N/A", "N/A", "N/A"

    col1, col2, col3 = st.columns(3)

    with col1:
        kpi_card("App Struggle", difficulty, accent_color="#010101")
    with col2:
        kpi_card("Productivity Hit", prod_impact, accent_color="#1877F2")
    with col3:
        kpi_card("Sleep Impact", sleep_imp, accent_color="#E1306C")

    st.markdown("<div style='height:20px'></div>", unsafe_allow_html=True)

def show_impact_charts(filtered_df):

    border_style = """
        <style>
        div[data-testid="stVerticalBlockBorderWrapper"] {
            border: 1.5px solid #C5C8D9 !important;
            border-radius: 12px !important;
            background-color: #F7F8FC !important;
        }
        </style>
    """
    st.markdown(border_style, unsafe_allow_html=True)

    social_colors = ["#D94169", "#FFFC00", "#1877F2", "#E1306C", "#FF0000", "#25D366"]

    # ===== الصف الأول: Lollipop + Donut =====
    col1, col2 = st.columns(2, gap="medium")

    with col1:
        with st.container(border=True):
            feel_count = (
                filtered_df.groupby("feeling_after_closing")["user_id"]
                .nunique()
                .reset_index()
            )
            feel_count.columns = ["Feeling", "Users"]

            # Lollipop بدل Bar
            fig1 = go.Figure()

            for i, row in feel_count.iterrows():
                fig1.add_trace(go.Scatter(
                    x=[0, row["Users"]],
                    y=[row["Feeling"], row["Feeling"]],
                    mode="lines",
                    line=dict(color="#C5C8D9", width=2.5),
                    showlegend=False
                ))

            fig1.add_trace(go.Scatter(
                x=feel_count["Users"],
                y=feel_count["Feeling"],
                mode="markers+text",
                marker=dict(
                    size=16,
                    color=social_colors[:len(feel_count)],
                    line=dict(color="white", width=2)
                ),
                text=feel_count["Users"],
                textposition="middle right",
                textfont=dict(size=12, color="#002333"),
                showlegend=False
            ))

            fig1.update_layout(
                title=dict(text="Feeling After Closing App",
                           font=dict(size=14), y=0.97, x=0.5,
                           xanchor="center", yanchor="top"),
                height=230,
                margin=dict(t=45, b=20, l=10, r=55),
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                xaxis=dict(showgrid=True, gridcolor="#E0E3EF",
                           title="Users", tickfont=dict(size=11)),
                yaxis=dict(showgrid=False, title="", tickfont=dict(size=11))
            )
            st.plotly_chart(fig1, use_container_width=True)

    with col2:
        with st.container(border=True):
            family_impact = (
                filtered_df.groupby("phone_during_family")["user_id"]
                .nunique()
                .reset_index()
            )
            family_impact.columns = ["Behavior", "Users"]

            fig2 = px.pie(
                family_impact,
                names="Behavior",
                values="Users",
                hole=0.5,
                title="Phone Usage During Family Time",
                color_discrete_sequence=social_colors
            )
            fig2.update_traces(
                textinfo="percent+label",
                textfont=dict(size=12)
            )
            fig2.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(text="Phone Usage During Family Time",
                           y=0.97, x=0.5, xanchor="center", yanchor="top",
                           font=dict(size=14)),
                legend=dict(font=dict(size=11), orientation="v", x=1, y=0.5),
                margin=dict(t=45, b=20, l=10, r=10),
                height=230
            )
            st.plotly_chart(fig2, use_container_width=True)

    # ===== الصف التاني: Box + Funnel =====
    col3, col4 = st.columns(2, gap="medium")

    with col3:
      with st.container(border=True):
        struggle_hours = (
            filtered_df.groupby(["difficulty_closing_app", "daily_watch_hours"])["user_id"]
            .nunique()
            .reset_index()
        )
        struggle_hours.columns = ["App Struggle", "Daily Watch Hours", "Users"]

        fig3 = px.bar(
            struggle_hours,
            x="App Struggle",
            y="Users",
            color="Daily Watch Hours",
            barmode="stack",
            title="Watch Hours vs App Struggle",
            color_discrete_sequence=social_colors
        )
        fig3.update_layout(
            height=230,
            margin=dict(t=45, b=20, l=10, r=10),
            plot_bgcolor="#F7F8FC",
            paper_bgcolor="#F7F8FC",
            title=dict(font=dict(size=14), y=0.97, x=0.5,
                       xanchor="center", yanchor="top"),
            xaxis=dict(title="App Struggle", tickfont=dict(size=11)),
            yaxis=dict(title="Users", tickfont=dict(size=11)),
            legend=dict(
                orientation="h",
                y=-0.3,
                x=0.5,
                xanchor="center",
                font=dict(size=10)
            )
        )
        st.plotly_chart(fig3, use_container_width=True)
    with col4:
        with st.container(border=True):
            opinion_count = (
                filtered_df.groupby("family_opinion")["user_id"]
                .nunique()
                .reset_index()
            )
            opinion_count.columns = ["Opinion", "Users"]

            fig4 = px.funnel(
                opinion_count,
                x="Users",
                y="Opinion",
                title="Family Opinion on Usage",
                color_discrete_sequence=social_colors
            )
            fig4.update_layout(
                height=230,
                margin=dict(t=45, b=20, l=10, r=10),
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                title=dict(font=dict(size=14), y=0.97, x=0.5,
                           xanchor="center", yanchor="top"),
                showlegend=False
            )
            st.plotly_chart(fig4, use_container_width=True)
def show_impact_dashboard():

    st.markdown("## 🧠 Social & Psychological Impact Analysis")

    # ================= FILTERS =================

    st.sidebar.subheader("🔽 Impact Filters")

    selected_genders = st.sidebar.multiselect(
        "Gender",
        options=df_full["gender"].unique(),
        default=[]
    )

    selected_segments = st.sidebar.multiselect(
        "User Segment",
        options=df_full["user_segment"].unique(),
        default=[]
    )

    # ================= AUTO FALLBACK =================

    if not selected_genders:
        selected_genders = df_full["gender"].unique()

    if not selected_segments:
        selected_segments = df_full["user_segment"].unique()

    # ================= FILTER DATA =================

    mask = (
        df_full["gender"].isin(selected_genders) &
        df_full["user_segment"].isin(selected_segments)
    )

    filtered_impact_df = df_full[mask]

    # ================= COMPONENTS =================

    show_impact_KPIs(filtered_impact_df)
    st.markdown("---")
    show_impact_charts(filtered_impact_df)



#------------------------
#show_overview_dashboard
#-----------------------

def show_platform_cards(filtered_df):

    platforms = {
    "TikTok": "tik-tok.png",
    "Facebook Reels": "facebook.png",
    "Instagram Reels": "instagram.png",
    "YouTube Shorts": "youtube.png",
    "Snapchat Spotlight": "snapchat.png",
    "Other": "social-media.png"
}

    cols = st.columns(6)

    total_users = len(filtered_df)

    for col, (platform, img) in zip(cols, platforms.items()):

        with col:

            # عدد المستخدمين
            count = len(
                filtered_df[
                    filtered_df["primary_platform"] == platform
                ]
            )

            # النسبة
            percentage = (
                count / total_users * 100
                if total_users > 0 else 0
            )

            # الصورة
            st.image(
                    img,
                  width=40

)

        

            # النسبة
            st.markdown(
                f"""
                <p style='
                    text-align:center;
                    font-size:18px;
                    color:#421A59;
                    margin-top:-10px;
                '>
                    {percentage:.1f}%
                </p>
                """,
                unsafe_allow_html=True
            )

def show_overview_charts(filtered_df):

    border_style = """
        <style>
        div[data-testid="stVerticalBlockBorderWrapper"] {
            border: 1.5px solid #C5C8D9 !important;
            border-radius: 12px !important;
            background-color: #F7F8FC !important;
        }
        </style>
    """
    st.markdown(border_style, unsafe_allow_html=True)

    social_colors = ["#FFFC00", "#E1306C","#1877F2" , "#FF0000", "#25D366","#DC0841" ]

    # ===== الصف الأول: Lollipop + Pie =====
    col1, col2 = st.columns(2, gap="medium")

    with col1:
        with st.container(border=True):
            feel_count = (
                filtered_df.groupby("feeling_after_closing")["user_id"]
                .nunique()
                .reset_index()
            )
            feel_count.columns = ["Feeling", "Users"]

            fig1 = go.Figure()

            for i, row in feel_count.iterrows():
                fig1.add_trace(go.Scatter(
                    x=[0, row["Users"]],
                    y=[row["Feeling"], row["Feeling"]],
                    mode="lines",
                    line=dict(color="#C5C8D9", width=2),
                    showlegend=False
                ))

            fig1.add_trace(go.Scatter(
                x=feel_count["Users"],
                y=feel_count["Feeling"],
                mode="markers+text",
                marker=dict(
                    size=16,
                    color=["#DD0E45", "#1B3C73", "#535D73"],
                    line=dict(color="white", width=2)
                ),
                text=feel_count["Users"],
                textposition="middle right",
                textfont=dict(size=12, color="#002333"),
                showlegend=False
            ))

            fig1.update_layout(
                title="Feeling After Closing App",
                height=250,
                margin=dict(t=40, b=10, l=10, r=40),
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                xaxis=dict(showgrid=True, gridcolor="#E0E3EF", title="Users"),
                yaxis=dict(showgrid=False, title="")
            )
            st.plotly_chart(fig1, use_container_width=True)

    with col2:
        with st.container(border=True):
            segment_count = (
                filtered_df.groupby("user_segment")["user_id"]
                .nunique()
                .reset_index()
            )
            segment_count.columns = ["User Segment", "Count"]

            fig2 = px.pie(
                segment_count,
                names="User Segment",
                values="Count",
                title="User Segment",
                hole=0.5,
                color_discrete_sequence=["#DC0841", "#1B3C73", "#C5C8D9", "#535D73"]
            )
            fig2.update_layout(
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                font_color="#002333",
                title=dict(y=0.95, x=0.5, xanchor="center", yanchor="top"),
                margin=dict(t=30, b=10, l=10, r=10),
                height=250
            )
            st.plotly_chart(fig2, use_container_width=True)

    # ===== الصف التاني: Age Bar + Influence Bar =====
    col3, col4 = st.columns(2, gap="medium")

    with col3:
        with st.container(border=True):
            age_count = (
                filtered_df.groupby("age_group")["user_id"]
                .nunique()
                .reset_index()
            )
            age_count.columns = ["Age Group", "Users"]

            fig3 = px.bar(
                age_count,
                x="Age Group",
                y="Users",
                title="Users by Age Group",
                color="Age Group",
                text="Users",
                color_discrete_sequence=social_colors
            )
            fig3.update_layout(
                height=250,
                margin=dict(t=40, b=10, l=10, r=10),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
                xaxis_title="Age Group",
                yaxis_title="Users"
            )
            fig3.update_traces(textposition="outside")
            st.plotly_chart(fig3, use_container_width=True)

    with col4:
        with st.container(border=True):
            infl = (
                filtered_df.groupby("purchase_influence_level")["user_id"]
                .nunique()
                .reset_index()
            )
            infl.columns = ["Influence", "Users"]

            fig4 = px.bar(
                infl,
                x="Users",
                y="Influence",
                orientation="h",
                text="Users",
                title="Purchase Influence Level",
                color="Influence",
                color_discrete_sequence=social_colors
            )
            fig4.update_layout(
                height=250,
                margin=dict(t=40, b=10, l=10, r=10),
                showlegend=False,
                plot_bgcolor="#F7F8FC",
                paper_bgcolor="#F7F8FC",
            )
            st.plotly_chart(fig4, use_container_width=True)

def show_overview_gender(filtered_df):

    male_count = filtered_df[filtered_df["gender"] == "Male"]["user_id"].nunique()
    female_count = filtered_df[filtered_df["gender"] == "Female"]["user_id"].nunique()
    total_users = filtered_df["user_id"].nunique()

    if total_users == 0:
        male_percentage = 0
        female_percentage = 0
    else:
        male_percentage = (male_count / total_users) * 100
        female_percentage = (female_count / total_users) * 100

    col1, col2 = st.columns(2, gap="large")

    with col1:
        c1, c2 = st.columns([1, 6])
        with c1:
            st.image("male.gif", width=100)  # ← كبّرنا الأيقونة
        with c2:
            st.markdown(f"""
            <div style="line-height:1.3; padding-top:6px;">
                <div style="font-size:30px; font-weight:bold; color:#1B3C73;">
                    {male_count}
                </div>
                <div style="font-size:16px; color:gray;">
                    {male_percentage:.1f}% Male
                </div>
            </div>
        """, unsafe_allow_html=True)

    with col2:
        c1, c2 = st.columns([1, 6])
        with c1:
            st.image("profile.gif", width=100)  # ← كبّرنا الأيقونة
        with c2:
            st.markdown(f"""
            <div style="line-height:1.3; padding-top:6px;">
                <div style="font-size:30px; font-weight:bold; color:#D94169;">
                    {female_count}
                </div>
                <div style="font-size:16px; color:gray;">
                    {female_percentage:.1f}% Female
                </div>
            </div>
        """, unsafe_allow_html=True)

    # ← مسافة صغيرة بين الـ gender وبين البلاتفورم
    st.markdown("<div style='height:25px'></div>", unsafe_allow_html=True)

def show_overview_dashboard():

    # ================= FILTERS =================

    st.sidebar.subheader("🔽 Overview Filters")

    gender = st.sidebar.multiselect(
        "Gender",
        options=df_full["gender"].unique(),
        default=[]
    )

    age_group = st.sidebar.multiselect(
        "Age Group",
        options=df_full["age_group"].unique(),
        default=[]
    )

    segment = st.sidebar.multiselect(
        "User Segment",
        options=df_full["user_segment"].unique(),
        default=[]
    )

    purchase = st.sidebar.multiselect(
        "Purchase Status",
        options=df_full["purchased_from_video"].unique(),
        default=[]
    )

    # ================= AUTO FALLBACK =================

    if not gender:
        gender = df_full["gender"].unique()

    if not age_group:
        age_group = df_full["age_group"].unique()

    if not segment:
        segment = df_full["user_segment"].unique()

    if not purchase:
        purchase = df_full["purchased_from_video"].unique()

    # ================= FILTER DATA =================

    filtered_df = df_full[
        (df_full["gender"].isin(gender)) &
        (df_full["age_group"].isin(age_group)) &
        (df_full["user_segment"].isin(segment)) &
        (df_full["purchased_from_video"].isin(purchase))
    ]

    # ================= COMPONENTS =================

    st.markdown("<div style='height:20px'></div>", unsafe_allow_html=True)

    show_overview_gender(filtered_df)

    show_platform_cards(filtered_df)

    st.markdown("---")

    show_overview_charts(filtered_df)



# ==============================
# MAIN NAVIGATION LOGIC
# ==============================

if page == "🏠 Overview":
   show_overview_dashboard()
   #pass

elif page == "📊 Who Are the Users?":
    show_users_dashboard()

elif page == "📱 How Do They Use Reels?":
    show_reels_dashboard()

elif page == "🛒 Purchase Behavior":
    show_purchase_dashboard()
    #pass

elif page == "🧠 Social & Psychological Impact":
    
    show_impact_dashboard()






